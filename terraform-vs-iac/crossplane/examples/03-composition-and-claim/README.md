# 03 — Composition + Claim ≈ module + variables

## Terraform (this repo)

**Root:** [05c-use-modules/main.tf](../../../../05-modules/05c-use-modules/main.tf)

```hcl
variable "prefix" {
  type    = string
  default = "web"
}

module "pet" {
  source = "./modules/pet"
  prefix = var.prefix
  length = 2
}

output "pet_name" {
  value = module.pet.name
}
```

**Child module:** [modules/pet/main.tf](../../../../05-modules/05c-use-modules/modules/pet/main.tf) — hides `random_pet` + `local_file`; caller only passes `prefix` and `length`.

| Terraform | Crossplane |
|---|---|
| `module` source + arguments | **Claim** `.spec` (app team) |
| Child module resources | **Composition** templates **MRs** |
| `variable` / `output` | **XRD schema** / **`.status`** |
| `module.pet.name` | `kubectl get claim ... .status` |

## Crossplane idea

App team creates a **Claim** (`StorageBucket`) in their namespace. Platform team owns **XRD** + **Composition** that expands to real `Bucket` MR — same encapsulation as `./modules/pet`.

## Files (read in order)

1. [`01-xrd.yaml`](01-xrd.yaml) — public API (allowed fields on Claim).
2. [`02-composition.yaml`](02-composition.yaml) — how Claim spec maps to MR `forProvider`.
3. [`03-claim-app-team.yaml`](03-claim-app-team.yaml) — app team input only.

This example uses a **minimal** bucket wrapper (one MR). Real platforms compose many MRs (SG, KMS, …) like a large Terraform module.

**Next:** [04-environment-config](../04-environment-config/README.md)
