# 04 — EnvironmentConfig ≈ shared `data` / platform tfvars

## Terraform (this repo)

**Idea from** [4a data sources](../../../../04-configuration/04a-resources-and-data/main.tf):

```hcl
data "local_file" "unit" {
  filename = local_file.unit.filename
}

resource "local_file" "consumer" {
  content = data.local_file.unit.content
}
```

Platform stacks often use **`data "aws_vpc"`** or **remote state outputs** so app modules receive `vpc_id` without managing the VPC. See [resources & data note](../../crossplane-vs-terraform-resources-and-data.md).

## Crossplane idea

**EnvironmentConfig** holds **per-environment constants** (region, shared VPC id, tag defaults). **Compositions** read them when patching MRs — like platform-wide tfvars the app Claim never sees.

| Terraform | Crossplane |
|---|---|
| `data.aws_vpc.main.id` | `EnvironmentConfig.data.vpcId` patched into MR |
| `terraform.tfvars` (platform) | EnvironmentConfig selected by labels |

## Files

1. [`01-environmentconfig-prod.yaml`](01-environmentconfig-prod.yaml) — platform-owned values.
2. [`02-composition-uses-env.yaml`](02-composition-uses-env.yaml) — patch excerpt using `FromEnvironmentFieldPath`.

**Next:** [05-connection-secret](../05-connection-secret/README.md)
