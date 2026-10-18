# Crossplane vs Terraform — `resource` and `data`

Sixth note in the Crossplane series. On the Associate exam, **`resource` vs `data`** is objective **4a** ([04a — resources and data](../../04-configuration/04a-resources-and-data/README.md)): managed vs read-only, addresses (`aws_instance.web` vs `data.aws_ami.ubuntu`).

**Not on the exam:** how Crossplane maps those ideas.

Related: [overview](crossplane-vs-terraform.md) (MRs), [modules & compositions](crossplane-vs-terraform-modules-and-compositions.md), [variables & inputs](crossplane-vs-terraform-variables-and-inputs.md).

---

## One-line mapping

| Terraform | Crossplane |
|---|---|
| **`resource`** | **Managed resource (MR)** — one CR per cloud object, lifecycle owned by the provider controller |
| **`data`** | **No single block** — you **reference** existing values via **other CRs**, **EnvironmentConfig**, **Secrets**, **status** of composed resources, or **import/adopt** into an MR |
| **`kubernetes_*` resource** | Usually **not Crossplane** — use core K8s / Helm / GitOps; Crossplane MRs are for **cloud** APIs |
| **`kubernetes_*` data** | Read another **Kubernetes object** in a Composition patch / function — not Terraform’s `data` syntax |

**Kubernetes and `data`:** Crossplane runs **on** the Kubernetes API, so “look something up” often means **read another object in etcd** (Secret, EnvironmentConfig, another CR’s `.status`). That is **similar in spirit** to `data "kubernetes_*"`, but **not** the same as Terraform’s broad **`data "aws_vpc"`** story unless the platform models it explicitly (for example via EnvironmentConfig or import).

---

## `resource` — what Terraform means

From [4a](../../04-configuration/04a-resources-and-data/README.md):

- Terraform **creates, updates, destroys** the object.
- It lives in **state** as managed (`aws_instance.web`, not `data.`).
- Remove the block → next **apply** plans **destroy** (if still in state).

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "my-logs"
}
```

---

## Crossplane analog: **Managed Resource (MR)**

An MR is the same **ownership** idea in CR form:

```yaml
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: example-logs
spec:
  forProvider:
    region: eu-central-1
  providerConfigRef:
    name: default
```

| | **TF `resource`** | **Crossplane MR** |
|---|---|---|
| **Declaration** | HCL block | CR `.spec` (`forProvider`, …) |
| **Identity** | State binding + cloud id | CR metadata + **external name** / provider-assigned id in **`.status`** |
| **Lifecycle** | `apply` / `destroy` | Controller reconcile; **delete CR** → often **delete cloud** (check **deletion policy** / finalizers) |
| **Drift** | Next `plan` | Controller loop corrects toward spec (with eyes open on surprises) |

**Composite resource (XR)** and **Claim** are **not** a replacement for one `resource` block — they are **wrappers** that **compose many MRs** from one spec ([modules note](crossplane-vs-terraform-modules-and-compositions.md)). One MR ≈ one `resource`.

**`terraform_data`**, **`null_resource`**: no cloud object — Crossplane has no exact twin; use K8s **Job**, **ConfigMap**, or keep that logic in Terraform.

---

## `data` — what Terraform means

- **Read only** — Terraform does **not** take lifecycle ownership of the thing queried.
- Still stored in **state** as last read (`data.aws_vpc.main.id`).
- Delete the `data` block → **no destroy** of the VPC in AWS.

Common uses: existing VPC, AMI lookup, `terraform_remote_state`, `aws_iam_policy_document` (computed JSON).

---

## Crossplane: there is no `data` block

Crossplane’s language is **Kubernetes objects**, not HCL. Nothing says `data "aws_vpc" "main"`. Instead you choose a pattern:

### 1. Platform-published constants — **EnvironmentConfig**

Closest to “everyone reads the same VPC id” without managing that VPC in the same Claim:

- Platform team maintains **EnvironmentConfig** (region, `vpcId`, subnet ids, tags).
- **Composition** patches those fields onto MR `.spec`.

Like **`data` + locals in the platform root**, or **tfvars** only the platform touches — not app teams.

### 2. Reference another composed stack — **XR / Claim status**

Like wiring `module.network.vpc_id` into a child module:

- Lower-level **XR** exposes **`.status`** (e.g. subnet ids).
- Higher **Composition** patches **fromCompositeFieldPath** / **fromEnvironmentFieldPath** into child MR fields.

Terraform does that with **module outputs**; Crossplane does it with **status + patches** (still in-cluster, not `terraform_remote_state`).

### 3. Kubernetes **Secret** / **ConfigMap**

Like `data.kubernetes_secret` or injecting values:

- **ProviderConfig** `secretRef` for cloud credentials.
- Composition reads **Secret** keys for non-cloud config (not a substitute for all AWS lookups).

This **is** “referred from K8s resources” — but only for **what you stored in the cluster**, not arbitrary live AWS queries unless a controller filled that Secret.

### 4. **Import / adopt** existing cloud into an MR

If the VPC **already exists** and you want Crossplane to **own** it going forward:

- Create MR with **external-name** / import flow (provider-specific) so the controller **binds** to the existing id.
- That object is now a **`resource`**, not **`data`** — same tradeoff as Terraform **`import`**: you chose management.

There is usually **no** permanent “read this VPC every reconcile but never own it” block like `data.aws_vpc` unless the provider offers an **observe-only** MR kind (uncommon; design varies by provider).

### 5. **`terraform_remote_state`**

No built-in Crossplane equivalent.

| Approach | Idea |
|---|---|
| **EnvironmentConfig** per env | Platform copies network outputs from Terraform apply (CI writes Config) |
| **Separate MRs** for shared infra | Network MRs in mgmt cluster; app Compositions reference status |
| **Keep boundary** | VPC stays **Terraform**; Crossplane only resources **inside** that network |

A common boundary ([reference platforms](../../reference-platforms.md)): **Terraform** builds network and cluster; Crossplane (if used) targets resources **above** that line.

### 6. Computed-only values (no API object)

`data "aws_iam_policy_document"` — policy JSON from HCL rules.

Crossplane: **Composition functions** (CEL, go-templating, patch-and-transform) build strings/maps in the reconcile pipeline — not a `data` address in state.

---

## Side-by-side table

| You want to… | **Terraform** | **Crossplane** |
|---|---|---|
| Create and own S3 bucket | `resource "aws_s3_bucket"` | MR `Bucket` |
| Use existing VPC id in a new resource | `data "aws_vpc"` + `resource` referencing `data...id` | **EnvironmentConfig** or XR **status** patch; or **import** VPC as MR |
| Read K8s Secret for config | `data "kubernetes_secret"` | **Secret** reference in Composition / ProviderConfig |
| Read another TF stack’s outputs | `data "terraform_remote_state"` | Platform sync → **EnvironmentConfig**; or don’t split ownership |
| Query AMI on every plan | `data "aws_ami"` | Pin AMI in Composition literal, **EnvironmentConfig**, or MR field updated by pipeline — no standard `data` |
| Drop from config | `resource` → destroy; `data` → no cloud destroy | Delete MR → often cloud delete; remove patch source → depends on design |

---

## Kubernetes provider confusion (Terraform vs Crossplane)

| Tool | Role of Kubernetes |
|---|---|
| **Terraform `hashicorp/kubernetes`** | **Client** of the API — `resource` = manage objects in **state**; `data` = **read** objects |
| **Crossplane** | **Server-side** — manifests create **CRs** on the API; cloud MRs are **one kind** of CR |

So:

- **App Deployments / Services** → GitOps or TF kubernetes provider — **not** typical Crossplane MRs.
- **S3 / RDS / IAM in AWS** → Crossplane **provider-aws** MRs — analog to TF **`aws_*` resources**, not to `kubernetes_deployment`.

Crossplane does **not** replace every `data "kubernetes_*"` — it **is** Kubernetes for **cloud** resources. In-cluster reads are **object references** in YAML/patches, like informers, not `data` blocks.

---

## Mental model diagram

```text
TERRAFORM                         CROSSPLANE
─────────                         ──────────

resource "aws_*"        ───────►  MR (Bucket, VPC, …)
       │                               │
       │ owns lifecycle                │ owns lifecycle (deletion policy)
       ▼                               ▼
     state                            CR in etcd + .status

data "aws_*"            ───────►  no block — pick one:
       │                          • EnvironmentConfig (platform ids)
       │ read, no destroy           • patch from XR.status
       ▼                          • import → becomes MR (owned)
     state cache                   • Secret/ConfigMap (cluster-held facts)
```

---

## Exam reminder (Terraform only)

- Managed → **`resource`**; read → **`data.`** prefix in references.
- **`ephemeral`** (4h) — read without persisting in state; Crossplane has no direct exam analog.

---

## Related notes

- [04a — resource and data](../../04-configuration/04a-resources-and-data/README.md)  
- [07a — import](../../07-maintain/07a-import/README.md) — brownfield binding (TF) vs MR import (Crossplane)  
- [crossplane-vs-terraform-modules-and-compositions.md](crossplane-vs-terraform-modules-and-compositions.md)  
- [declarative-terraform-and-kubernetes.md](../declarative-terraform-and-kubernetes.md)  

**External:** [Crossplane Managed Resources](https://docs.crossplane.io/latest/concepts/managed-resources/), [EnvironmentConfig](https://docs.crossplane.io/latest/concepts/environment-configs/).
