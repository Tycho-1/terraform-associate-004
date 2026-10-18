# 05 — Connection Secret ≈ sensitive `output`

## Terraform (this repo)

**Outputs:** [4c-variables-and-outputs](../../../../04-configuration/04c-variables-and-outputs/README.md)

```hcl
output "pet_name" {
  value = module.pet.name
}
```

**Sensitive / not in state:** [4h-sensitive-data](../../../../04-configuration/04h-sensitive-data/README.md) — `sensitive = true` redacts UI; **ephemeral** / **write-only** keep secrets out of state.

## Crossplane idea

Providers can write connection details (endpoint, username, generated password) into a **Kubernetes Secret** in the app namespace — like a **sensitive output** delivered to a secure channel, not printed in `kubectl get claim` spec.

| Terraform | Crossplane |
|---|---|
| `output "db_host" { sensitive = true }` | **`.status`** fields + **connection Secret** |
| `writeConnectionSecretToRef` N/A | MR / Composition sets `writeConnectionSecretToRef` |

Secrets in Git: **reference only** — see [secrets note](../../crossplane-vs-terraform-secrets-and-sensitive-data.md).

## Files

1. [`01-composition-connection-secret.yaml`](01-composition-connection-secret.yaml) — patch connection secret target (illustrative RDS-shaped MR).
2. [`02-claim-no-password-in-git.yaml`](02-claim-no-password-in-git.yaml) — Claim references optional existing Secret; never inline password.

**Next:** [06-workflow](../06-workflow/README.md) — init/plan/apply/destroy parallels.

**Back to index:** [examples README](../README.md)
