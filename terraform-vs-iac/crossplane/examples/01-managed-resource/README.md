# 01 — Managed resource ≈ `resource`

## Terraform (this repo)

**File:** [04a-resources-and-data/main.tf](../../../../04-configuration/04a-resources-and-data/main.tf)

```hcl
resource "local_file" "unit" {
  filename = "${path.module}/unit.txt"
  content  = "hello from a managed resource\n"
}
```

- **`resource`** = Terraform **manages** lifecycle (create, update, destroy).
- Address in state: `local_file.unit`.

## Crossplane idea

A **Managed Resource (MR)** is one CR per cloud object. The provider controller **owns** reconcile — like `resource`, not `data`.

| Terraform | Crossplane |
|---|---|
| `resource "aws_s3_bucket" "logs"` | `kind: Bucket` (provider CRD) |
| State stores id | `.status` + external name on the CR |
| `terraform apply` | `kubectl apply` + controller loop |

## Files

- [`02-bucket-mr.yaml`](02-bucket-mr.yaml) — desired S3 bucket in `.spec.forProvider` (needs `ProviderConfig` from [lesson 02](../02-provider-and-config/README.md)).

## Try it

After Crossplane + AWS provider are installed on a **sandbox** account:

```bash
kubectl apply -f ../02-provider-and-config/02-providerconfig-default.yaml
kubectl apply -f 02-bucket-mr.yaml
kubectl get bucket.example-logs -o yaml   # adjust name per metadata.name
```

Deleting the CR typically triggers **cloud delete** — use a disposable account.

**Next:** [02-provider-and-config](../02-provider-and-config/README.md)
