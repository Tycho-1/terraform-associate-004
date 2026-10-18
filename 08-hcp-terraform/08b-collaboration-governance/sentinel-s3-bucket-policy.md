# Example: Sentinel policy on an S3 bucket plan

Companion to [8b — Policy](README.md#policy). Tutorial: [Write a Sentinel policy](https://developer.hashicorp.com/terraform/tutorials/policy/sentinel-policy). Production libraries: [terraform-sentinel-policies](https://github.com/hashicorp/terraform-sentinel-policies), [policy-library AWS sets](https://github.com/hashicorp?q=policy-library+aws+terraform).

## When Sentinel runs

On HCP Terraform, a normal run looks like this ([8a](../08a-create-infrastructure#a-run-in-order)):

```text
plan  →  policy check (Sentinel / OPA)  →  confirm  →  apply
```

**Sentinel** evaluates the **saved plan** — the proposed creates/updates/deletes — **before apply** can change real infrastructure. A **hard-mandatory** failure **stops the run**; apply never starts.

Sentinel does **not** run inside your root module `.tf` files. Policies live in a **policy set** in the organization, attached to a workspace or project.

## Scenario (exam-style)

**Rule:** Every new `aws_s3_bucket` in the plan must:

1. **Block public access** (private-by-default posture).
2. **Enable server-side encryption** (SSE).

**Mechanism:** Import `tfplan/v2` and inspect `resource_changes` for `aws_s3_bucket`, `aws_s3_bucket_public_access_block`, and `aws_s3_bucket_server_side_encryption_configuration`.

## Terraform configuration that satisfies the rule

Modern AWS provider style uses **separate** resources for public access block and encryption (not only inline blocks on the bucket). Example: [s3-bucket-compliant.tf.example](s3-bucket-compliant.tf.example).

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "example-org-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

A plan that **omits** the public access block or SSE configuration would still show an `aws_s3_bucket` **create** — Sentinel can **deny** that run.

## Teaching Sentinel policy (simplified)

File: [s3-private-and-encrypted.sentinel.example](s3-private-and-encrypted.sentinel.example)

This version is **shorter than HashiCorp’s published PCI/ISO libraries** on purpose. It checks that:

- Any planned **public access block** has all four `block_*` / `restrict_*` flags **true**.
- Any planned **SSE configuration** sets `sse_algorithm` to **AES256** or **aws:kms**.
- If the plan **creates** at least one bucket, it must also plan **at least one** public-access block and **at least one** SSE configuration resource.

A real org policy would **match each bucket** to its `public_access_block` and `server_side_encryption_configuration` by `bucket` reference. The exam usually tests **ideas**: policy reads the **plan**, runs **before apply**, enforcement levels — not full Sentinel syntax.

Register the policy in a policy set: [sentinel-policy-set.hcl.example](sentinel-policy-set.hcl.example).

```hcl
policy "s3-private-and-encrypted" {
  source            = "./s3-private-and-encrypted.sentinel"
  enforcement_level = "hard-mandatory"
}
```

Attach the policy set to the **project** or **workspace** in HCP Terraform.

## What a violation looks like

| Plan contains | Policy result (hard-mandatory) |
|---|---|
| Bucket + public access block + SSE | Pass → run can continue to apply (if other policies pass) |
| Bucket only, no SSE / no public access block | Fail → **apply blocked** |
| Public access block with `block_public_acls = false` | Fail |

## Sentinel vs OPA vs `check` blocks

| | **Sentinel / OPA (HCP)** | **`check` block (Terraform language)** |
|---|---|---|
| Runs where | HCP **policy check** stage on the **plan** | End of **plan/apply** in the CLI or remote run |
| Written in | Sentinel or Rego | HCL |
| Typical failure | Stops run (by enforcement level) | **Warning** only |

## OPA

HCP Terraform also supports **OPA** (Rego) on the same plan JSON. Same stage as Sentinel; different language. The Associate objective mentions both; Sentinel is the common HashiCorp tutorial path.
