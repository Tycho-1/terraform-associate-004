# Crossplane vs Terraform — modules and compositions

Fifth note in the Crossplane series. **Terraform modules are Associate objective 5** ([05-modules](../../05-modules/README.md)). Crossplane does **not** ship a `module` block — but it **does** have a first-class reuse story: **Compositions**, **XRDs**, **Claims**, and **packages**. Without that layer, teams either copy raw Managed Resource YAML or over-expose cloud CRDs to everyone.

Related: [variables & inputs](crossplane-vs-terraform-variables-and-inputs.md) (the module *interface*), [overview](crossplane-vs-terraform.md) (platform features).

**Not on the exam.**

---

## Short answer

| Question | Answer |
|---|---|
| Does Crossplane have “modules”? | **No** as a language feature — yes as a **platform pattern**. |
| Closest analog | **`module` + `variable` + `output`** ≈ **XRD + Composition + Claim** (optional) |
| Raw MR with no Composition | Like writing **all resources in root `.tf`** with no child modules — works, does not scale for self-service |
| Distributing reuse | **Module registry** / git source ≈ **Configuration package** (XRDs + Compositions in a bundle) |

Crossplane does not use the word **module**, but **Compositions** and **Claims** cover the same reuse problem with different names and UX.

---

## What a Terraform module is doing

A **child module** is a **black box**:

- **Inputs:** `variable` blocks → caller passes `module "x" { ... }` arguments  
- **Internals:** `resource` / `data` the caller does not edit directly  
- **Outputs:** `output` blocks → parent uses `module.x.attr`  
- **One instance per `module` block** (or many via `count` / `for_each` on the block)

```text
root module
  module "network" { cidr = var.vpc_cidr }
  module "database" { vpc_id = module.network.vpc_id }
```

**Plan** walks the **whole tree**: you see creates/destroys for nested resources before apply. **State** records every resource address (`module.network.aws_subnet.private[0]`, …).

Study: [05a sources](../../05-modules/05a-module-sources), [05b scope](../../05-modules/05b-variable-scope), [05c use](../../05-modules/05c-use-modules), [05d versions](../../05-modules/05d-module-versions).

---

## What Crossplane uses instead

```text
App team          Platform team                    Cloud
────────          ─────────────                    ─────

Claim.spec  ──►   Composition  ──►  XR  ──►  MR + MR + MR
(optional         (patches,         (composed   (S3, RDS,
 public API)       functions)        instance)    SG, …)
```

| Terraform | Crossplane | Role |
|---|---|---|
| **Root module** | Platform repo / **Configuration** that installs XRDs + Compositions | Defines what exists in the cluster |
| **`module` block call** | App creates **Claim** (or cluster-scoped **XR**) | “I want one instance of the platform API” |
| **Child module body** | **Composition** template (MRs + patches) | Hidden implementation |
| **`variable`** | **XRD schema** on Claim/XR | Allowed inputs |
| **`output`** | **`.status`** on Claim/XR, **connection Secrets** | Values back to consumer |
| **`module` source** (git, registry) | **Configuration package** / GitOps applying XRD+Composition YAML | Ship platform APIs to many clusters |
| **`version = "x.y.z"`** on registry module | **Provider / Configuration package** version, Composition **revision** | Pin what runs |

**Managed resource (MR)** alone is one cloud object — like a single `resource` in `.tf`, not a module.

**Composition** is the reusable **bundle**: one Claim spec becomes many MRs with consistent naming, tags, and networking.

**Claim** is the **tenant-facing module call**: namespace-scoped, RBAC-friendly; app teams never see the Composition YAML if you forbid it.

---

## Side-by-side — “I want a standard Postgres for my app”

### Terraform (platform team publishes a module)

Platform maintains `modules/postgres/` with variables `size`, `environment`, outputs `endpoint`.

App / env root:

```hcl
module "app_db" {
  source      = "git::https://example.com/platform.git//modules/postgres?ref=v2.1.0"
  environment = var.environment
  size        = "small"
}
```

Consumer needs **Terraform access**, **state** for that root, and **permission to run apply** (or HCP workspace).

### Crossplane (platform team publishes an API)

Platform installs **XRD** `PostgreSQLInstance`, **Composition** that creates `RDSInstance`, `SecurityGroup`, `SubnetGroup`, patches fields from Claim → MRs.

App team:

```yaml
apiVersion: example.io/v1alpha1
kind: PostgreSQLInstance
metadata:
  name: orders-db
  namespace: team-orders
spec:
  environment: prod
  storageGB: 50
```

Consumer needs **RBAC to create that Claim** in their namespace — not cloud console, not full MR types.

---

## Features modules have that Compositions approximate differently

| Capability | **Terraform module** | **Crossplane Composition** |
|---|---|---|
| **Hide implementation** | Caller only sees variables | Caller only sees Claim schema; MR types cluster-scoped or denied by RBAC |
| **Nested reuse** | Module calls module | Composition references other XRs or patches across MRs; **nested** patterns need design (multiple Compositions or functions) |
| **Review before change** | `terraform plan` shows full module diff | Manifest diff + admission; no single built-in “plan all MRs” like TF |
| **Version pin** | `?ref=v1.2.3` on git module, registry version | Package version on cluster; change Composition → new revisions affect **new** XRs (existing XRs behavior depends on update policy) |
| **Many instances** | `count` / `for_each` on `module` | Many **Claims** (one per app/db) |
| **Conditional resources** | `count = var.enable_x ? 1 : 0` | Composition **functions**, patch **fromComposite** / transforms, or separate Compositions |
| **Tests** | `terraform test`, plan in CI | Policy tests, composition render tests, integration in sandbox cluster |
| **Public registry** | registry.terraform.io | Upbound marketplace / your git; no single global equivalent to HashiCorp Registry for *compositions* |

---

## What Crossplane adds beyond “module”

Modules are **call-time reuse in HCL**. Crossplane adds **runtime product** semantics:

| Idea | Why it is not just a module |
|---|---|
| **Namespace-scoped Claims** | Multi-tenant self-service on shared mgmt cluster — TF modules do not enforce K8s namespace boundaries by themselves |
| **Continuous reconcile** | Composition output is kept aligned until Claim deleted — module runs once per apply |
| **API evolution** | XRD **served versions** (`v1`, `v2`) like Kubernetes API versioning — modules version by source ref |
| **Composition functions** | Pipeline steps (patch, transform, go-templating, CEL) — like codegen inside the platform, not in caller repo |

---

## When Crossplane feels like it has “no modules”

Usually one of these:

1. **Only MRs installed** — provider-aws `Bucket` CR used directly everywhere → like everyone editing root `main.tf` with no shared module. **Fix:** add XRD + Composition + Claim.
2. **Platform team does not publish a Claim** — only cluster admins create XRs → like only DevOps runs Terraform; app teams file tickets. **Fix:** expose Claim, lock down MR RBAC.
3. **Expecting `module` source in app repo** — app repos hold **Claim YAML** (or Helm values), not Composition. Compositions live in **platform** git, like module source in a **platform** repo.
4. **Comparing to HCP no-code modules** — Terraform Cloud can expose a module as a UI with variables; Crossplane exposes **Kubernetes API** (Claim) instead.

---

## Nested and layered platforms

| Pattern | **Terraform** | **Crossplane** |
|---|---|---|
| **Network + app stacks** | Root calls `module.network` then `module.app` with `vpc_id` output | Lower Composition (VPC XR) + higher Composition (app XR) referencing **EnvironmentConfig** or XR status |
| **Org guardrails** | Sentinel on plan, separate state per env | OPA/Gatekeeper on Claims, separate **ProviderConfig** per account |
| **Same bundle, many clusters** | Same module ref, different tfvars / workspace | Same Configuration package, different **EnvironmentConfig** per cluster |

Terraform **output → module input** wiring is explicit in HCL. Crossplane wiring is **patches** in Composition (and optional **EnvironmentConfig** for shared ids). See [variables note](crossplane-vs-terraform-variables-and-inputs.md).

---

## Anti-patterns (both sides)

| Anti-pattern | Problem |
|---|---|
| **Two modules managing one resource** | Two TF modules or roots same bucket — state fight |
| **TF module + Crossplane Composition same bucket** | Two writers — pick a boundary |
| **Giant Composition** | Giant module nobody can plan/review — split Compositions or XRDs |
| **Claim schema = entire MR schema** | Leaks cloud API — defeats encapsulation like exporting every `resource` argument as a variable |

---

## Exam vs platform learning

| | **Associate exam** | **This note** |
|---|---|---|
| **Modules** | Sources, `module` block, outputs, versioning | How that *idea* maps to Crossplane |
| **Crossplane** | Out of scope | When Compositions replace modules in K8s-centric platforms |

---

## Related notes

- [crossplane-vs-terraform.md](crossplane-vs-terraform.md) — Claim → XR → Composition summary  
- [crossplane-vs-terraform-variables-and-inputs.md](crossplane-vs-terraform-variables-and-inputs.md) — inputs and outputs  
- [05-modules](../../05-modules/README.md) — Terraform module objectives  
- [terraform-vs-iac hub](../README.md)  

**External:** [Crossplane — Compositions](https://docs.crossplane.io/latest/concepts/compositions/), [Composite Resource Definitions](https://docs.crossplane.io/latest/concepts/composite-resource-definitions/), [Configuration packages](https://docs.crossplane.io/latest/concepts/packages/).
