# Crossplane vs Terraform

Part of the [Crossplane series](README.md) · [terraform-vs-iac](../README.md).

This note is for platform design — how two declarative systems differ when both “provision cloud infrastructure.” Shorter K8s comparison: [declarative-terraform-and-kubernetes.md](../declarative-terraform-and-kubernetes.md). Linked [reference platforms](../../reference-platforms.md) use **Terraform for cloud + cluster** and **GitOps inside the cluster** for apps.

## One-sentence each

| | **Terraform** | **Crossplane** |
|---|---|---|
| **What it is** | CLI + language (HCL) + **providers** that call cloud APIs; **state** remembers what was created | **Kubernetes controllers** + **CRDs** that call cloud APIs; the **cluster API** holds desired specs |
| **Mental model** | “Run `plan` / `apply` when we approve a change” | “Apply a manifest; a controller **keeps reconciling** until spec matches the cloud” |

Both are **declarative** (desired end state, not imperative scripts). The split is **where state lives**, **when reconciliation runs**, and **who operates the system** (pipeline vs control plane).

---

## “Backend” and memory of the world

Terraform and Crossplane both need to know **which real cloud object** belongs to **which declaration**. They store that differently.

### Terraform: state + backend

| Piece | Role |
|---|---|
| **Configuration** (`.tf`) | Desired shape: resource types, arguments, modules |
| **State** (`terraform.tfstate` or remote blob) | Maps `aws_instance.web` → `i-0abc…`, tracks dependencies, tracks attributes for the next plan |
| **Backend** (`backend "s3"`, `cloud { }`, …) | **Where the state file is stored** and **locking** — not where EC2 runs |

- **Plan** compares **config + state** to provider refresh → proposed diff.
- **Apply** executes the diff and **updates state**.
- Without state, Terraform cannot safely update or destroy what it created (except `import` / `terraform state` surgery).
- **HCP Terraform** adds remote state **plus** run history, remote execution, RBAC, policy — still Terraform’s state model. See [hcp-vs-open-source-cli.md](../../08-hcp-terraform/hcp-vs-open-source-cli.md).

```text
Git (.tf)  +  state file  +  terraform plan/apply  →  AWS/Azure/GCP APIs
```

### Crossplane: Kubernetes API (etcd) — no Terraform state

| Piece | Role |
|---|---|
| **Custom resources** (YAML) e.g. `Bucket`, `RDSInstance`, `XR` | Desired spec in the **Kubernetes API** |
| **Provider controllers** (Crossplane provider-aws, etc.) | Watch CRs, call cloud APIs, write **`.status`** on the CR |
| **etcd** | Stores all objects; **not** a separate “Crossplane state file” per resource type |

- You (or GitOps) **`kubectl apply`** (or create via CI) a manifest.
- The **provider’s reconciliation loop** creates/updates/deletes cloud resources to match **`.spec`**.
- Identity binding is **on the CR** (metadata, external-name annotations, provider config) — analogous to state’s `id`, but visible as a K8s object with `status.conditions`.

```text
Git (CR YAML)  →  Kubernetes API  →  Crossplane provider reconcile loop  →  cloud APIs
```

### Comparison table — “backend”

| Question | **Terraform** | **Crossplane** |
|---|---|---|
| Where is “what we manage” recorded? | **State file** (per workspace/root module) | **CRs in the cluster** (+ `.status`) |
| Remote storage of that record? | S3, GCS, Azure, HCP workspace, … | **etcd** (cluster backup is your disaster recovery story) |
| Locking concurrent writers? | Backend / HCP lock | Kubernetes **resourceVersion** + admission; one writer per object field with server-side apply |
| Can you `plan` without changing cloud? | **Yes** — core workflow | **No native `plan`** like Terraform; you dry-run admission, use `--server-side` diff tools, or policy on manifests |
| Delete manifest / remove from `.tf` | TF apply **destroys** (if removed from config and still in state) | CR delete often triggers **cloud delete** (depends on deletion policy / finalizers) — must design carefully |

---

## Providers: how cloud APIs are plugged in

Both systems need a **translation layer** from declarative config to AWS/Azure/GCP API calls. Terraform uses **provider plugins** loaded by the CLI. Crossplane uses **provider packages** that run as **controllers** in Kubernetes and register **CRDs**.

Study detail for Terraform providers: [2b — How providers work](../../02-fundamentals/02b-how-providers-work), [2a — versions and registry](../../02-fundamentals/02a-provider-versions). HCP credentials: [provider-credentials.md](../../08-hcp-terraform/provider-credentials.md).

### Terraform provider model

```text
terraform init  →  download provider binaries (registry / mirror / private registry)
terraform plan/apply  →  core starts plugin process(es)  →  RPC  →  cloud API
```

| Piece | What it does |
|---|---|
| **`required_providers`** in `terraform { }` | Declares **which** plugins and **version constraints**; `terraform init` installs them |
| **`provider "aws" { ... }` block** | Configures **one** plugin instance: region, endpoints, features; optional **`alias`** for a second config |
| **Resource type prefix** | `aws_s3_bucket` → provider local name `aws` (before first `_`) |
| **Lifecycle** | Plugin runs **during plan/apply** on the machine (or HCP worker) that executes Terraform — not a long-running service |
| **Credentials** | `provider` arguments, env vars (`AWS_*`, `ARM_*`), shared config files, or HCP **dynamic credentials** on the workspace — never committed keys in Git |

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Second account/region: provider "aws" { alias = "replica" ... }
# resource uses: provider = aws.replica
```

- **Registry:** public [registry.terraform.io](https://registry.terraform.io), private registry on HCP, filesystem/network mirrors ([2a](../../02-fundamentals/02a-provider-versions)).
- **Custom providers:** you ship a **binary**; consumers set `source` to your private registry namespace ([2b proprietary API example](../../02-fundamentals/02b-how-providers-work)).
- **Kubernetes resources:** `hashicorp/kubernetes` and `hashicorp/helm` are normal providers — same plugin model, same state.

### Crossplane provider model

```text
Install Provider package (YAML)  →  controller Deployment + CRDs in cluster
Apply Managed Resource CR       →  provider controller reconciles  →  cloud API
```

| Piece | What it does |
|---|---|
| **Provider package** (`Provider` / `provider.pkg.crossplane.io`) | Installs a **provider revision** — controller image + generated **CRDs** (e.g. `Bucket`, `VPC`) into the cluster |
| **Provider controller** | Long-running **Pod(s)** watching CRs; calls cloud APIs on every reconcile — like a Terraform provider, but **always on** |
| **Managed resource (MR)** | One CR per cloud object; `.spec` is desired cloud shape; `.status` holds conditions, external name, observed state |
| **`ProviderConfig`** | **Credentials and account** for a family of MRs (which AWS account, which GCP project) — closest analog to Terraform’s `provider` block |
| **`providerConfigRef`** on MR / Composition | Selects **which** `ProviderConfig` reconciles this resource |
| **Upgrades** | Bump provider package version → new CRD schema / controller; cluster admin operation, not `terraform init` |

Typical install and credential sketch (illustrative API versions; adjust to your Crossplane major version):

```yaml
# 1) Install the AWS family provider package (cluster admin)
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: xpkg.upbound.io/upbound/provider-aws-s3:v1.21.0
---
# 2) Credentials + default AWS context (often IRSA / Workload Identity / secretRef)
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: IRSA   # or Secret, PodIdentity, etc.
---
# 3) Desired S3 bucket — reconciled continuously
apiVersion: s3.aws.upbound.io/v1beta1
kind: Bucket
metadata:
  name: example-logs
spec:
  forProvider:
    region: eu-west-1
  providerConfigRef:
    name: default
```

Many Crossplane providers are built with **upjet** — they **generate** Kubernetes CRDs and controllers from Terraform Provider schemas. So the **same cloud API knowledge** often originates from Terraform provider code, but the **runtime shape** (CR + loop in-cluster) is different.

### Side-by-side — providers

| Topic | **Terraform** | **Crossplane** |
|---|---|---|
| **Unit of plug-in** | Provider **binary** (plugin) | Provider **package** (controller + CRDs) |
| **Install** | `terraform init` | `kubectl apply` Provider manifest / Crossplane CLI |
| **Version pin** | `required_providers` + lock file | Provider package tag (`xpkg.../provider-aws-s3:vX.Y.Z`) |
| **Configure cloud auth** | `provider` block + env / HCP workspace | **`ProviderConfig`** CR (+ K8s secrets / IRSA) |
| **Multiple accounts** | Multiple `provider` blocks with **`alias`** | Multiple **`ProviderConfig`** + `providerConfigRef` |
| **Resource declaration** | `resource "aws_s3_bucket" "x" { }` in HCL | `kind: Bucket` CR with `spec.forProvider` |
| **When API calls run** | During **plan/apply** only | **Reconcile loop** while CR exists |
| **Binding to cloud ID** | **State** `id` attribute | CR **status**, annotations (`crossplane.io/external-name`) |
| **Where it runs** | Laptop, CI runner, HCP worker | **Pods in management cluster** |
| **Private / custom APIs** | Custom provider binary + private registry | Custom provider package (build/publish OCI xpkg) — heavier ops |

### Credentials — same cloud, different wiring

| Cloud | **Terraform (typical)** | **Crossplane (typical)** |
|---|---|---|
| AWS | `AWS_*` env, shared credentials file, or HCP `TFC_AWS_*` dynamic role | **IRSA** on provider ServiceAccount, or `ProviderConfig` → Secret |
| Azure | `ARM_*` env or HCP `TFC_AZURE_*` | Workload identity / service principal secret in `ProviderConfig` |
| GCP | `GOOGLE_APPLICATION_CREDENTIALS` / HCP `TFC_GCP_*` | Workload identity + `ProviderConfig` |

Terraform **remote** runs use workspace env ([provider-credentials.md](../../08-hcp-terraform/provider-credentials.md)). Crossplane uses **the cluster’s** identity machinery — if the management cluster is wrong, **every** MR using that `ProviderConfig` is wrong.

### Operational differences that matter

- **Terraform:** one `init` per root module; providers are **files on disk** (or cached). No provider Pod to patch except upgrading plugin version and re-running apply.
- **Crossplane:** provider controllers are **part of cluster blast radius** — upgrade, scale, monitor, and secure them like any critical control plane. CRD schema changes can require **migrating** MR manifests.
- **Two providers, one stack:** Terraform references `provider = aws.west` on resources. Crossplane sets `providerConfigRef` per MR or in a Composition template.

**Exam reminder:** Associate **004** tests Terraform **`required_providers`**, `provider` blocks, and registry/mirrors — not Crossplane `Provider` packages.

---

## Reconciliation: batch vs loop

### Terraform — reconcile **on demand**

1. Someone or CI runs **`terraform plan`** (optional save).
2. Human/policy approves.
3. **`terraform apply`** runs once.
4. Between applies, **drift** (console edits) stays until the next plan/apply (HCP **health assessment** can **report** drift; it does not auto-fix by default).

Strength: **explicit change windows**, readable destroy lines, saved plans.

Weakness: **no continuous healing** — a manually deleted resource stays gone until the next apply.

### Crossplane — reconcile **continuously**

1. CR exists in the API with a **spec**.
2. Provider controller **requeues** on a timer or on watch events.
3. If cloud diverges from spec, controller **pushes cloud back** toward spec (or updates `.status` / conditions on failure).

Strength: **always-on** convergence; fits “platform team publishes APIs; app teams claim databases.”

Weakness: **surprise changes** if spec is wrong or too broad; less natural “single reviewed plan” for huge blast radius unless you gate writes (policy, composition only, no direct XR access).

### GitOps angle

| | **Terraform GitOps** | **Crossplane + GitOps** |
|---|---|---|
| Pattern | PR → `terraform plan` → merge → `apply` | PR → merge → Flux/Argo applies **CRs** → controllers reconcile |
| Reconcile | **Batch** on pipeline | **Loop** in cluster |
| Compare | [declarative-terraform-and-kubernetes.md — GitOps](../declarative-terraform-and-kubernetes.md) | Same doc; Crossplane CRs are just more K8s objects |

Crossplane does **not** require Flux or Argo CD as a product dependency; production setups usually add **Git-backed delivery** (Flux, Argo, or CI apply from Git). See [GitOps and delivery](crossplane-vs-terraform-gitops-and-delivery.md).

---

## What Crossplane adds (platform features)

Terraform has **modules** and **variables** ([modules & compositions](crossplane-vs-terraform-modules-and-compositions.md), [inputs](crossplane-vs-terraform-variables-and-inputs.md)). Crossplane has a **Kubernetes-native platform layer**:

| Concept | Purpose |
|---|---|
| **Managed resource (MR)** | One CR type ≈ one cloud API shape (e.g. `Bucket` from provider-aws) |
| **Composite resource (XR) / Composition** | Platform-defined **bundle** of MRs (VPC + subnets + rules) from one spec |
| **Claim** | Namespace-scoped **self-service** face of an XR — app team creates `PostgreSQLInstance` without editing raw MR YAML |
| **ProviderConfig** | Credentials / account binding — see [Providers](#providers-how-cloud-apis-are-plugged-in) |
| **Functions** (newer pipelines) | Mutate/validate compositions in the reconcile path (policy-ish, composable) |

Terraform equivalent is roughly: **root module + child modules + optional stack** (Terraform Stacks are a different HashiCorp product direction). Crossplane’s **Claim → XR → Composition → MRs** is optimized for **multi-tenant K8s** and **RBAC on namespaces**.

Terraform’s equivalent self-service story is often: **small root modules**, **HCP workspaces**, **Terraform Cloud no-code modules**, or **wrappers in CI** — not in-cluster CRs.

---

## Approach differences (design)

| Dimension | **Terraform** | **Crossplane** |
|---|---|---|
| **Control plane** | CLI / HCP / CI | **Kubernetes API** |
| **Interface for app teams** | PR to infra repo, vars, ServiceNow, portal running TF | **kubectl**, GitOps, **Claims**, internal portals emitting CRs |
| **Change review** | **`plan`** is first-class | Review **manifest diff** + policy (OPA/Kyverno/Sentinel on TF; admission/policy on K8s) |
| **Multi-cloud in one place** | One state can hold AWS + Azure + GCP resources | One cluster can run multiple provider controllers; still one operational home (the cluster) |
| **Blast radius of control plane** | State file / workspace compromise | **Cluster compromise** exposes all ProviderConfigs and CRs |
| **Day-2 operations** | `apply`, `import`, `state rm`, `-replace` | Edit CR spec, deletion policies, pause annotations, provider logs |
| **Ecosystem** | Huge **public provider** registry | Growing **provider-upjet** ecosystem; tied to K8s operator model |
| **Running workloads** | Usually **not** — use K8s for Pods | **Same cluster** as apps (by design) |

Neither replaces the other automatically. Many orgs: **Terraform builds the cluster and network**; **Crossplane or in-cluster operators** optional on top for app-level infra.

---

## What is better when?

### Prefer **Terraform** when…

- You want the industry-default **plan → review → apply** loop for **networks, IAM, org guardrails, data stores, and the Kubernetes cluster itself**.
- The team running infra is **not** centered on Kubernetes operations.
- You need **broad providers** (SaaS, DNS, GitHub, random one-off APIs) with one workflow.
- **Import / moved / state refactor** matter for brownfield (7x maintain objectives).
- You use **HCP Terraform** for RBAC, policy on plans, remote execution, audit — without running a management cluster.
- **Reference platforms** pattern: TF to AKS/EKS/GKE, GitOps **inside** for apps ([reference-platforms.md](../../reference-platforms.md)).

### Prefer **Crossplane** when…

- You already run a **production Kubernetes control plane** and want **cloud resources as CRs** in the same model as Deployments.
- **Platform engineering** wants **self-service Claims** (databases, buckets) with **namespace RBAC**, not full TF repos for every team.
- You want **continuous reconciliation** toward spec (with eyes open on deletion and drift behavior).
- Internal developers live in **kubectl / GitOps / Backstage** emitting YAML, not `terraform apply`.
- You accept operating **provider pods**, upgrades, and **cluster security** as the cost of unification.

### Often **both** (boundary, not either/or)

```text
Terraform (or OpenTofu)     →  VPC, cluster, IAM baseline, shared DNS
        ↓
Kubernetes cluster
        ↓
Flux / Argo CD              →  app Deployments
Optional Crossplane         →  app-team Claims for S3/RDS/etc.
```

**Anti-pattern:** managing the same S3 bucket with **both** Terraform state and a Crossplane `Bucket` CR — two writers, same as TF **and** Helm for the same Deployment ([declarative doc — use each at its boundary](../declarative-terraform-and-kubernetes.md)).

---

## Quick reference diagram

```text
                    TERRAFORM                         CROSSPLANE
                    ---------                         ----------

Desired state       .tf in Git                        CR YAML in Git / API

Cloud plug-in       provider plugin (init/registry)   Provider package + ProviderConfig

Memory / binding      STATE (backend/HCP)               CR spec + status in etcd

Execution           plan / apply (batch)              controller loop (continuous)

Typical operator      platform / SRE / CI               K8s platform team + GitOps

Review artifact       terraform plan output             manifest diff, conditions

Drift handling        next plan (+ HCP health alert)    reconcile toward spec

Exam focus            Associate 004 core                Out of scope — context only
```

---

## Related study notes

- [crossplane-vs-terraform-state-and-resilience.md](crossplane-vs-terraform-state-and-resilience.md) — **etcd vs S3 state**, DR, blast radius, “is separate state more secure?”
- [crossplane-vs-terraform-audit-dr-and-recovery.md](crossplane-vs-terraform-audit-dr-and-recovery.md) — **audit / run history**, point-in-time recovery, DR drills (S3 vs HCP vs Velero)
- [crossplane-vs-terraform-variables-and-inputs.md](crossplane-vs-terraform-variables-and-inputs.md) — **`variable` / tfvars / HCP** vs **XRD, Claim, Composition, EnvironmentConfig**
- [crossplane-vs-terraform-modules-and-compositions.md](crossplane-vs-terraform-modules-and-compositions.md) — **`module`** vs **Composition, Claim, Configuration package**
- [crossplane-vs-terraform-resources-and-data.md](crossplane-vs-terraform-resources-and-data.md) — **`resource` / `data`** vs **Managed Resource**, references, EnvironmentConfig
- [crossplane-vs-terraform-secrets-and-sensitive-data.md](crossplane-vs-terraform-secrets-and-sensitive-data.md) — **`sensitive` / ephemeral / write-only / env** vs **K8s Secrets, ESO, IRSA**
- [crossplane-vs-terraform-gitops-and-delivery.md](crossplane-vs-terraform-gitops-and-delivery.md) — **Flux/Argo** vs CI; Crossplane without GitOps
- [02b — Terraform providers](../../02-fundamentals/02b-how-providers-work) — plugins, registry, `provider` blocks
- [declarative-terraform-and-kubernetes.md](../declarative-terraform-and-kubernetes.md) — Terraform vs kube controllers, GitOps
- [06-state — backends](../../06-state/06c-remote-backend/README.md) — what Terraform backends do and do **not** do
- [08 — HCP Terraform](../../08-hcp-terraform/README.md) — hosted operations without Crossplane
- [terraform-and-ansible.md](../ansible/terraform-and-ansible.md) — another “declarative but different transport” comparison style

**Further reading (external):** [Crossplane docs](https://docs.crossplane.io/), [Terraform docs](https://developer.hashicorp.com/terraform).
