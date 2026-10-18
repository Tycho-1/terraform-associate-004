# Crossplane vs Terraform — variables, inputs, and “who sets what”

Fourth companion in the Crossplane series. **Terraform variables are core Associate material** ([4c — variables and outputs](../../04-configuration/04c-variables-and-outputs/README.md), [HCP vs `TF_VAR_*`](../../08-hcp-terraform/hcp-variables-and-tf-var.md)). Crossplane has **no `variable` block** — inputs are **API schema + patches + platform data**. This note maps the concepts so self-service and env-specific defaults make sense in both worlds.

Series index: [crossplane/README.md](README.md). Other parts: [overview](crossplane-vs-terraform.md) · [modules & compositions](crossplane-vs-terraform-modules-and-compositions.md) · [state & resilience](crossplane-vs-terraform-state-and-resilience.md) · [audit & DR](crossplane-vs-terraform-audit-dr-and-recovery.md).

---

## Yes — inputs matter in both

| Why it matters | **Terraform** | **Crossplane** |
|---|---|---|
| **App team vs platform team** | Root **variables** + modules; platform owns `.tf`, teams pass **tfvars** or HCP vars | Platform owns **XRD + Composition**; teams create **Claims** with only allowed **spec** fields |
| **Environments** | `dev` / `prod` via **workspace**, **tfvars**, or **variable sets** | **Namespace**, labels, **EnvironmentConfig**, or separate Claims per env |
| **Secrets** | `sensitive` variables, CI/HCP secrets, never commit plaintext | **Kubernetes Secrets**, **External Secrets**, **ProviderConfig** creds — not in Git |
| **Validation** | `validation` blocks, `type` constraints | **OpenAPI schema** on XRD, admission policy, **Composition functions** |
| **Outputs back to callers** | **`output`** blocks, `terraform output`, remote state | **`.status`** on XR/Claim, **Connection secrets**, published fields in schema |

If you skip this layer, you either hard-code everything in platform code or let app teams edit raw cloud CRs — both are painful.

---

## Mental map (one picture)

```text
TERRAFORM (module = reusable package)
  variable "size"     ──►  used inside module/resources
  module "db" { db_size = var.size }
  output "endpoint"   ──►  caller / remote state consumer

CROSSPLANE (platform API = Kubernetes type)
  XRD schema          ──►  which fields exist on Claim/XR (types, required, enums)
  Claim.spec.size     ──►  app team input (namespace-scoped)
  Composition patches ──►  map spec → Managed Resource .spec (platform wiring)
  XR.status           ──►  observed / connection info back to Claim
```

**Terraform:** inputs are **explicit language constructs** (`variable`, `module` arguments).  
**Crossplane:** inputs are **fields on a CR**; the platform **restricts** which fields exist via **XRD** and **how they flow** via **Composition**.

---

## Side-by-side — “declare an input”

| | **Terraform** | **Crossplane** |
|---|---|---|
| **Declaration** | `variable "instance_class" { type = string ... }` in a module | **`CompositeResourceDefinition` (XRD)** — `spec.versions[].schema.openAPIV3Schema` for Claim and/or XR |
| **Who sees it** | Any caller of the module (or root vars for app teams) | Fields exposed on **Claim** (typical self-service) or only on cluster-scoped **XR** |
| **Default** | `default = "db.t3.micro"` in `variable` | **OpenAPI `default`** on schema fields, or **literal** in Composition patch when field omitted |
| **Required** | No `default` → caller must set | **`required`** in OpenAPI schema → API server rejects incomplete Claim |
| **Allowed values** | `validation { condition = contains([...], var.x) }` | **enum** in schema, or policy / composition function |
| **Sensitive** | `sensitive = true` (redacted in logs/UI) | **Do not put secrets in spec in Git** — use **Secret** refs, ESO, or provider-generated **writeConnectionSecretToRef** |

Example Terraform (module input):

```hcl
variable "environment" {
  type        = string
  description = "dev or prod tagging"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Must be dev or prod."
  }
}
```

Crossplane equivalent is **not** HCL — it is **schema on the Claim** plus patches in a **Composition** (simplified YAML shape):

```yaml
# XRD excerpt — app team may only set these on PostgreSQLInstance Claim
spec:
  versions:
    - name: v1
      schema:
        openAPIV3Schema:
          properties:
            spec:
              properties:
                storageGB:
                  type: integer
                  default: 20
                environment:
                  type: string
                  enum: [dev, prod]
              required: [environment]
```

Platform team maps `storageGB` → underlying `RDSInstance` MR in the **Composition** (`patches` / pipeline functions).

---

## Side-by-side — “supply a value at apply time”

| Source | **Terraform** | **Crossplane** |
|---|---|---|
| **Checked-in per env** | `terraform.tfvars`, `prod.auto.tfvars` | **GitOps** — different Claim YAML or Kustomize overlays per env |
| **CLI / CI without editing Git** | `-var`, `-var-file`, `TF_VAR_*` | `kubectl patch`, CI applying manifest, **Helm values** → Claim |
| **Hosted platform** | **HCP Terraform variables** (→ `var.*`) | No HCP analog — **HCP runs Terraform**, not Crossplane Claims |
| **Shell-only (not in state as var)** | **HCP environment variables**, `AWS_*` for providers | **Pod env** on provider controllers; not Claim fields |
| **Platform-wide defaults** | **Root module defaults**, shared `tfvars` in CI | **`EnvironmentConfig`** CRs selected by Composition (labels, refs) |
| **Computed / internal** | **`locals`**, data sources | **Composition literals**, **transforms**, **functions** — not on Claim |

Terraform **precedence** (CLI > env > tfvars > default) is documented for exams: [4c](../../04-configuration/04c-variables-and-outputs/README.md), [HCP precedence](../../08-hcp-terraform/08c-workspaces-and-projects/README.md#variable-precedence).

Crossplane has **no single global precedence list**. Order is: **schema default** → **Claim.spec** → **Composition patch logic** → **EnvironmentConfig** (when referenced) → **MR defaults** in provider CRD. Design it explicitly in the Composition.

---

## Modules vs Composition — passing inputs through

| Step | **Terraform** | **Crossplane** |
|---|---|---|
| **Platform packages a pattern** | **Child module** with its own `variable` blocks | **Composition** + **XRD** defining the public API |
| **Caller provides inputs** | `module "vpc" { cidr = var.vpc_cidr }` | User creates **Claim** `spec: { cidr: 10.0.0.0/16 }` |
| **Wiring to real resources** | Module body uses `var.*` on resources | **Patches** copy/transform Claim/XR fields → **Managed Resource** `.spec` |
| **Multiple resources from one input** | One module, many resources | One **XR** composed of many **MRs** from one Claim |
| **Hide implementation** | App team does not see child module `.tf` if they only run a wrapper root | App team only has RBAC to create **Claim**, not raw **RDSInstance** MR |

Terraform **child module** variables are set only by the **parent** `module` block.  
Crossplane **MR** fields are set only by the **Composition** (unless someone has cluster-admin and creates MRs directly — guard with RBAC).

---

## Outputs — returning values to consumers

| | **Terraform** | **Crossplane** |
|---|---|---|
| **Declare** | `output "db_host" { value = aws_db_instance.x.address }` | Publish fields in **XRD status schema**; populate via **Composition** `status` patches or controller behavior |
| **Consume** | `terraform output`, **remote state** `data.terraform_remote_state`, HCP outputs UI | `kubectl get claim -o yaml` → **`.status`**, or read **Connection Secret** (e.g. kubeconfig, DSN) |
| **Sensitive output** | `sensitive = true` | **Secret** object referenced from Claim/XR; restrict RBAC on `get secret` |

Crossplane often uses **writeConnectionSecretToRef** on composed resources so the app team gets credentials in a **namespace Secret** — closer to “output to a secure channel” than printing in plan logs.

---

## Environment and tenancy

| Pattern | **Terraform** | **Crossplane** |
|---|---|---|
| **Isolate prod/dev state** | Separate **backends** / **HCP workspaces** / state keys | Separate **namespaces**, clusters, or **ProviderConfigs** per account |
| **Same code, different values** | `*.tfvars` per workspace | Kustomize / Helm / separate Claim per env |
| **Org-wide constants** | **Variable sets** on HCP; shared `tfvars` in CI | **EnvironmentConfig** (region, vpcId, tags) merged in Composition |
| **Who may change prod inputs** | HCP **team** permissions, branch protection on tfvars | **RBAC** — who can create/update Claims in `prod` namespace |

---

## Secrets and credentials (not the same as a string variable)

| | **Terraform** | **Crossplane** |
|---|---|---|
| **Cloud API keys for provider** | `provider "aws" { ... }`, env vars, HCP dynamic credentials | **`ProviderConfig`** (often references a **Secret**) |
| **Password the app needs** | `random_password` + **sensitive** output / store in Vault | Provider generates → **Connection Secret** to namespace |
| **Anti-pattern** | `password = "hunter2"` in `.tf` | `password: hunter2` in Claim YAML in Git |

See [4h — sensitive data](../../04-configuration/04h-sensitive-data/README.md) for Terraform. Crossplane: [secrets & sensitive note](crossplane-vs-terraform-secrets-and-sensitive-data.md) (ESO is one option, not the whole story).

---

## HCP Terraform variables (exam) vs Crossplane

| Concept | **HCP + Terraform** | **Crossplane** |
|---|---|---|
| **UI-managed input to config** | Workspace **Terraform variable** → `var.name` | No first-class UI — **GitOps repo**, portal, or **Backstage** template filling Claim YAML |
| **Env var to shell only** | HCP **environment variable** (`TF_VAR_*`, `AWS_*`) | Provider **Deployment** env, **Workload Identity** — not Claim `spec` |
| **Reuse vars across many stacks** | **Variable sets** (project/org) | **EnvironmentConfig** + label selectors, or shared **ConfigMaps** (weaker typing) |

Teams that standardize on **HCP** for Terraform inputs often standardize on **GitOps + namespace** for Crossplane inputs.

---

## `locals` and data sources — “not inputs, but shape the result”

| | **Terraform** | **Crossplane** |
|---|---|---|
| **Derived values** | `locals { name = "${var.env}-app" }` | **Composition transforms**, **string** patches, **function** pipeline steps |
| **Read existing infra** | `data "aws_vpc" "main" { ... }` | **EnvironmentConfig** (platform publishes ids), or **MR** in **observe-only** patterns; no generic `data` block |
| **Caller must not set** | Locals are internal to module | Fields only on **XR** not exposed on **Claim** schema |

---

## Design checklist (platform team)

**Terraform**

- [ ] Required vs optional via `default` / `nullable` ([4c](../../04-configuration/04c-variables-and-outputs/README.md))  
- [ ] `validation` for enums and ranges  
- [ ] `sensitive` for anything credential-like  
- [ ] Clear **module interface** (variables in, outputs out)  
- [ ] HCP: **Terraform variable** vs **environment variable** vs `TF_VAR_*` ([hcp-variables-and-tf-var.md](../../08-hcp-terraform/hcp-variables-and-tf-var.md))  

**Crossplane**

- [ ] **XRD** defines the only fields app teams can set  
- [ ] **Composition** is the only writer to MRs (RBAC blocks direct MR create)  
- [ ] **EnvironmentConfig** for shared env constants (VPC id, region, tags)  
- [ ] **Connection secrets** for credentials; no secrets in Git  
- [ ] Test invalid Claim → API **validation** error (like `terraform validate`)  

---

## Quick reference table

| Terraform | Crossplane analogue |
|---|---|
| `variable` | **XRD schema** field on Claim/XR |
| `default` / `validation` | OpenAPI **default** / **enum** + policy |
| `terraform.tfvars` | Env-specific **Claim** YAML or overlays |
| `TF_VAR_*` / `-var` | **Patch** / CI-set fields on apply |
| HCP **Terraform variable** | External **portal** or GitOps param |
| HCP **variable set** | **EnvironmentConfig** + conventions |
| `module` argument | **Claim.spec** → Composition **patches** |
| `output` | **`.status`**, **Connection Secret** |
| `locals` | Composition **transforms** / functions |
| `provider` config | **ProviderConfig** |
| `sensitive` | **Secret** + RBAC, not spec in Git |

---

## Related notes

- [crossplane-vs-terraform.md](crossplane-vs-terraform.md) — Claims, Compositions, modules section  
- [locals-vs-variables.md](../../04-configuration/locals-vs-variables.md) — when not to use a variable in TF  
- [04c — variables and outputs](../../04-configuration/04c-variables-and-outputs/README.md)  
- [08-hcp-terraform/hcp-variables-and-tf-var.md](../../08-hcp-terraform/hcp-variables-and-tf-var.md)  

**External:** [Crossplane — Compositions](https://docs.crossplane.io/latest/concepts/compositions/), [Composite Resource Definitions](https://docs.crossplane.io/latest/concepts/composite-resource-definitions/), [EnvironmentConfig](https://docs.crossplane.io/latest/concepts/environment-configs/).
