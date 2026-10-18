# `cloud` block rules (exam)

Companion to [08d README](README.md). The `terraform { cloud { ... } }` block links a **root module** to HCP Terraform (or Terraform Enterprise with `hostname`).

## Allowed once per configuration

| Rule | Detail |
|---|---|
| Max **`cloud` blocks** | **1** per configuration (one root `terraform` block may contain at most one `cloud` block) |
| **`cloud` + `backend`** | **Not allowed** — mutually exclusive |
| Max **`backend` blocks** | **1** per configuration (same `terraform` block) |
| Several HCP workspaces | Configure inside the **single** `cloud` block — `workspaces { tags = [...] }` or `project`, not a second `cloud` |

Self-managed remote state uses **`backend "s3"`** (or GCS, Azure, …). HCP Terraform remote state and remote runs use **`cloud`**. Legacy HCP used **`backend "remote"`**; you still cannot combine that with **`cloud`** in one config.

## Invalid — two `cloud` blocks

```hcl
terraform {
  # ERROR — only one cloud block per configuration
  cloud {
    organization = "my-org"
    workspaces { name = "workspace-1" }
  }

  cloud {
    hostname     = "terraform.enterprise.com"
    organization = "my-enterprise-org"
    workspaces { name = "workspace-2" }
  }
}
```

Use **one** `cloud` block. For Terraform Enterprise, set **`hostname`** on that block instead of adding a second `cloud`:

```hcl
terraform {
  cloud {
    hostname     = "terraform.enterprise.com"
    organization = "my-enterprise-org"
    workspaces { name = "workspace-2" }
  }
}
```

## Invalid — `cloud` and `backend` together

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces { name = "app" }
  }

  backend "s3" {  # ERROR — mutually exclusive with cloud
    bucket = "my-state"
    key    = "app/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

Pick one path for **this** root module: HCP **`cloud`** or self-managed **`backend`**.

## Valid — one `cloud`, many workspaces via tags

One repository directory can target **multiple** HCP Terraform workspaces when they share the same code. Use **tags** (or **`project`**) in the lone `cloud` block — not multiple `cloud` blocks.

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      tags = ["prod", "networking"]
    }
  }
}
```

Terraform only allows workspaces whose tags match. Select which workspace to use with **`TF_WORKSPACE`** or the workspace prompt at **`terraform init`**. Example file: [cloud-tags.tf.example](cloud-tags.tf.example).

For exactly **one** fixed workspace, use **`workspaces { name = "network" }`** instead — see [cloud.tf.example](cloud.tf.example).

## `workspaces` sub-block — pick one style

Inside the single `cloud` block, use **one** of:

- `name` — bind to one HCP workspace name
- `tags` — allow any workspace in the org that has those tags
- `project` — allow workspaces in that project

Do not mix `name` with `tags` in the same `workspaces` block.

## `cloud` vs `backend "s3"` — remote state vs remote operations

**Exam statement (correct):** Using the **`cloud`** block enables **remote operations** on infrastructure managed by **HCP Terraform** or **Terraform Enterprise** — by default, **plan and apply run on the platform’s workers**, not only on your laptop.

| | **`backend "s3"`** (self-managed) | **`cloud { }`** (HCP / TFE) |
|---|---|---|
| **State** | Remote (S3 bucket) | Remote (HCP workspace) |
| **Where `plan` / `apply` run** | **Your machine** (or CI runner that invoked the CLI) | **HCP workers** by default (**remote execution**) |
| **Run history, UI, workspace vars, policy** | No (unless you build CI yourself) | Yes |

**Remote state** and **remote execution** are different. S3 gives shared, durable state; it does **not** move Terraform’s compute to HashiCorp. The **`cloud`** block wires both state **and** (usually) execution to the workspace.

**Caveat:** an HCP workspace can be set to **local execution mode** — state and locking still on HCP, but plan/apply run on your CLI machine (like S3 + login). **Agent** mode runs on your agents. Default on exam questions: **remote** execution.

Legacy **`backend "remote"`** was the older HCP form; it also targeted remote operations. You still cannot mix **`cloud`** and **`backend`** in one config.

## Related

- [6c — backend vs cloud](../../06-state/06c-remote-backend/README.md)
- [8c — CLI workspaces vs HCP workspaces](../08c-workspaces-and-projects/README.md)
