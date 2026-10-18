# 6c — Remote state with the backend block

Docs: [Backend configuration](https://developer.hashicorp.com/terraform/language/v1.12.x/backend), [state storage](https://developer.hashicorp.com/terraform/language/v1.12.x/state/backends).

A remote backend stores state somewhere other than the working directory: an S3 bucket, Azure Blob, GCS, Consul, an HTTP endpoint, or HCP Terraform. The `.tf` files stay on your machine or in Git. The state file does not.

## How to configure remote state (two mechanisms)

Remote state is always declared inside a top-level **`terraform { }` block**. There are **two** supported patterns — use **one**, not both:

| Mechanism | Block | Where state lives | Typical use |
|---|---|---|---|
| **Self-managed remote backend** | `backend "<type>" { ... }` | S3, GCS, Azure Blob, Consul, HTTP, … | Your cloud account; you manage the bucket and IAM |
| **HCP Terraform** | `cloud { ... }` | The linked **HCP Terraform workspace** | Teams, UI runs, locking, and governance on HashiCorp’s platform |

**Legacy HCP form:** `backend "remote" { ... }` still works but current docs prefer **`cloud`**. Exam 004 expects you to know **`cloud` replaces `backend`** for HCP — you **cannot** set `backend` and `cloud` in the same configuration. At most **one** `cloud` block; multiple HCP workspaces use **tags/project** inside that block. [8d — cloud block rules](../../08-hcp-terraform/08d-cli-integration/cloud-block-rules.md).

```hcl
# Option A — remote backend you operate (example: AWS S3)
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "app/terraform.tfstate"
    region = "eu-central-1"
  }
}

# Option B — HCP Terraform (state in a workspace)
terraform {
  cloud {
    organization = "example-org"
    workspaces {
      name = "network"
    }
  }
}
```

After you add or change either block, run **`terraform init`** (`-migrate-state` when moving off local state). Partial backend settings use **`-backend-config`** because the `backend` block cannot use variables.

**CLI workspaces vs remote storage:** `terraform workspace select dev` switches **which state object** a **backend** uses (for example different `key` or workspace prefix on S3). That is separate from choosing **`backend` vs `cloud`**. With **`cloud`**, environments are usually **separate HCP workspaces**, not `terraform workspace` on the CLI. See [cheatsheet — CLI vs HCP workspaces](../../cheatsheet.md#cli-workspaces-vs-hcp-terraform-workspaces) and [8d](../../08-hcp-terraform/08d-cli-integration).

```hcl
terraform {
  backend "s3" {
    bucket       = "my-terraform-state"
    key          = "network/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}
```

`backend-s3.tf.example` in this folder is that sketch. It is not initialized from this repo.

## Why migrate from local to remote? (exam benefits)

Local state lives on **one machine** as `terraform.tfstate`. Moving to a **remote** backend (S3, GCS, Azure Blob, HCP Terraform, …) is what teams do when collaboration and durability matter.

| Benefit | What it means |
|---|---|
| **Shared state for the team** | Everyone runs `plan` / `apply` against the **same** state object in the bucket/workspace — not copies on individual laptops. Required for more than one operator on one stack. See [6a](../06a-local-backend). |
| **State locking** | **Not all backends lock** — confirm yours before team use (S3 + DynamoDB or `use_lockfile`, HCP/`cloud`, etc.). Local lock only protects one filesystem. See [6b](../06b-locking). |
| **Encryption at rest** | Object storage backends use the cloud’s **server-side encryption** (SSE-S3 / SSE-KMS on AWS, encryption on GCS, Azure Storage encryption). You configure the bucket/account policy; Terraform stores the state blob there. State still contains secrets in plaintext **inside** the encrypted object — encryption protects the file at rest, not redaction inside JSON. |
| **Durability and versioning** | Buckets offer replication, versioning, and lifecycle rules — recovery if someone overwrites state or needs an older revision (operational backup; not a substitute for good process). |
| **Access control** | IAM / RBAC on the state bucket or HCP Terraform workspace permissions control **who** can read or write state, instead of emailing `terraform.tfstate`. |

**Not automatic:** remote backend does **not** by itself mean remote **execution** — `backend "s3"` still runs plan/apply on your laptop unless you use HCP Terraform remote operations ([8d](../../08-hcp-terraform/08d-cli-integration)). **Not a secrets vault:** move sensitive values out of state with ephemeral / write-only patterns where possible ([4h](../../04-configuration/04h-sensitive-data)).

Migration path:

```bash
terraform init -migrate-state
```

Copies existing local state into the new backend. See rules below.

## Rules that the exam likes

**One backend per configuration.** A second `backend` block is an error. Choosing a different backend means editing the block and re-initializing.

**No variables, locals, or functions inside the backend block.** The backend is configured before variables are evaluated. Every argument is a literal. This is the most common backend question.

**Secrets stay out of the block** by using partial configuration:

```hcl
terraform {
  backend "s3" {
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}
```

```bash
terraform init -backend-config="bucket=my-terraform-state"
```

`-backend-config` can be a `key=value` flag or a file. The partial values are not stored in the `.tf` files. They are stored in `.terraform` after init, on that machine.

**Changing backends is an init migration.**

```bash
terraform init -migrate-state
```

Terraform copies the existing state into the new backend and then uses it. `-reconfigure` tells Terraform to use the new backend settings and not copy state. You use reconfigure when the state is already in the new place, or when you are intentionally starting over. Migrating is the normal choice when you outgrow a local state file.

**HCP Terraform uses a `cloud` block, not `backend "remote"`, in current docs.** `backend "remote"` still works and is the older form. A configuration cannot set both `backend` and `cloud`. See [8d](../../08-hcp-terraform/08d-cli-integration).

## Reading another configuration's state

`terraform_remote_state` is a data source. It reads **outputs** from another state. It does not read resource attributes, and it does not let you change that other state.

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-terraform-state"
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}
```

The other configuration must output `vpc_id`. The identity you use to run Terraform needs permission to read that state object. For HCP Terraform the backend type in this data source is `remote`, with `organization` and `workspaces` in `config`. See [8c](../../08-hcp-terraform/08c-workspaces-and-projects).

Passing outputs between root modules this way couples them. Teams do it when two states must share a small set of ids (a VPC id, a cluster name). They keep the producer state's outputs small and stable.

## Apply stays local unless the backend says otherwise

The `s3` backend stores state remotely and still runs `plan` and `apply` on the machine where you invoked Terraform. HCP Terraform's remote operations run the plan on HashiCorp's workers. "Remote state" and "remote execution" are different. Objective 8 is remote execution.
