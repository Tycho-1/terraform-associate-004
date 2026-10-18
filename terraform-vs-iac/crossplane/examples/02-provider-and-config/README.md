# 02 — Provider package + ProviderConfig ≈ `provider` block

## Terraform (this repo)

**File:** [02c-multiple-providers/main.tf](../../../../02-fundamentals/02c-multiple-providers/main.tf)

```hcl
provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "replica"
  region = "us-west-2"
}

# resource "aws_s3_bucket" "x" { provider = aws.replica ... }
```

- **`required_providers`** + `terraform init` install plugins.
- **`provider`** block = config + credentials for one API client.
- **`alias`** = second client; resources pick `provider = aws.replica`.

## Crossplane idea

| Terraform | Crossplane |
|---|---|
| `terraform init` + provider binary | Install **Provider** package (controller + CRDs) |
| `provider "aws" { ... }` | **`ProviderConfig`** (region, credentials, role) |
| `provider = aws.replica` | **`providerConfigRef.name`** on each MR |

## Files (read in order)

1. [`01-provider-package.yaml`](01-provider-package.yaml) — install AWS family controller (cluster admin).
2. [`02-providerconfig-default.yaml`](02-providerconfig-default.yaml) — credentials / IRSA for one account.
3. [`03-providerconfig-replica.yaml`](03-providerconfig-replica.yaml) — second config (alias analog).
4. [`04-bucket-uses-replica.yaml`](04-bucket-uses-replica.yaml) — MR pointing at `replica`.

**Next:** [03-composition-and-claim](../03-composition-and-claim/README.md)
