# Terraform CLI workspaces vs HCP Terraform workspaces

Same English word, **two different features**. The Associate exam tests whether you know which one a question means. Local detail: [6a](06a-local-backend). HCP detail: [8c](../08-hcp-terraform/08c-workspaces-and-projects), [8d](../08-hcp-terraform/08d-cli-integration).

## What is a Terraform CLI workspace? (if you have never used one)

You have **one root module** — one folder of `.tf` files you run `terraform apply` in. **State** remembers which resources that apply created. If you want **two environments** (for example `dev` and `prod`) with the **same code** but **different** infrastructure, you need **two separate state files**. Otherwise dev and prod would fight over one state and try to manage the same resource addresses.

**CLI workspaces** are Terraform’s built-in way to keep **multiple state files** for **one configuration** without copying the whole directory.

```bash
terraform workspace list      # default, dev, prod, ...
terraform workspace new dev   # create a new named state slot
terraform workspace select dev
terraform workspace show      # which slot is active — run before apply
terraform apply               # only affects state for "dev"
```

### Where the state files go

| Backend | `default` workspace | Named workspace (e.g. `dev`) |
|---|---|---|
| **Local** (no remote backend) | `terraform.tfstate` | `terraform.tfstate.d/dev/terraform.tfstate` |
| **Remote** (e.g. S3) | Backend’s default key | Separate state object per workspace (prefix/key per workspace name) |

Same `.tf` on disk. **Different state file** per CLI workspace name. Switching workspace does **not** change your HCL; it changes **which state Terraform reads and writes**.

### `terraform.workspace` in configuration

Inside a module you can reference the **current CLI workspace name**:

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "myapp-${terraform.workspace}-logs"
}
```

With workspace `dev` selected, the bucket name includes `dev`. This only reflects **CLI workspace selection**. It is **not** an HCP Terraform workspace name unless you deliberately name them the same (and even then the mechanisms differ).

### What CLI workspaces do **not** give you

They are **only** a state partition inside one backend + one root module:

- No UI, run history, or approvals
- No workspace-scoped **variables** stored in a service (you use the same `terraform.tfvars` or pass `-var` — easy to apply wrong vars to wrong workspace)
- No teams, RBAC, or policy on a workspace
- No remote execution — plan/apply still run where you invoked the CLI
- No run triggers, drift assessments, or VCS integration

Many teams **never** use CLI workspaces in production. Common alternatives:

- **Separate directories** (`environments/dev`, `environments/prod`) or separate root modules
- **Separate HCP Terraform workspaces** (same repo, different workspace name / working directory / variables)

CLI workspaces are still fair game on the exam because the commands and `terraform.workspace` appear in docs and older tutorials.

### Footgun

The **selected** CLI workspace is easy to forget. `terraform workspace show` before `apply` is a habit. Applying while on `prod` when you thought you were on `dev` updates **prod’s state** with whatever vars you passed.

---

## What is an HCP Terraform workspace?

An **HCP Terraform workspace** (formerly Terraform Cloud workspace) is a **hosted object** in an **organization** (usually inside a **project**). It is **not** created with `terraform workspace new`.

Each HCP workspace has:

- **One** remote **state** (the source of truth for that stack)
- **Variables** (Terraform + environment), **variable sets**, optional **dynamic credentials**
- **Runs** (plan / apply history), execution mode (remote / local / agent)
- **Permissions** for teams, **Terraform version** pin, VCS settings, **policy sets**, **run triggers**, **health assessments**, etc.

You point a root module at it with the **`cloud`** block (or legacy `backend "remote"`):

```hcl
terraform {
  cloud {
    organization = "example-org"
    workspaces { name = "app-prod" }
  }
}
```

Or one configuration allowed to use several HCP workspaces via **tags** / **project**, selecting the target with **`TF_WORKSPACE`** at init or run time. See [cloud-block-rules.md](../08-hcp-terraform/08d-cli-integration/cloud-block-rules.md).

Switching “environment” in HCP means switching **which HCP workspace** this directory is bound to — **not** `terraform workspace select`.

When the **`cloud`** block is in use, **`terraform workspace` commands are not how you manage environments** on HCP. HashiCorp’s model is: one HCP workspace per environment (or per stack), not nested CLI workspaces on top.

**Exam note:** With HCP Terraform / `cloud`, **`terraform.workspace` in configuration is typically always `"default"`** during remote runs, because CLI workspaces are not in play. Do not rely on `terraform.workspace` to mean “HCP workspace name” on remote execution.

---

## Side-by-side comparison

| | **CLI workspace** (`terraform workspace`) | **HCP Terraform workspace** |
|---|---|---|
| **What it is** | A **name** for a state slot in the **current backend** | A **remote object** in an org (settings + state + runs) |
| **Created by** | `terraform workspace new <name>` | UI, API, `tfe` provider, or init with `cloud` block |
| **Selected by** | `terraform workspace select <name>` | `cloud.workspaces { name = ... }`, `TF_WORKSPACE`, or UI |
| **Same `.tf` code?** | Yes — one root module, many states | Yes — one repo can back many HCP workspaces |
| **Isolates state?** | **Yes** — core purpose | **Yes** — one state per HCP workspace |
| **Stores variables** | No (only your files / env on the runner) | **Yes** — workspace + variable sets |
| **Credentials for cloud APIs** | On the machine running Terraform | On workspace (env vars / dynamic creds) for **remote** runs |
| **Remote plan/apply** | No — local CLI unless you use another product | **Yes** — default remote execution |
| **Teams / RBAC** | No | **Yes** — team **Read/Plan/Write/Admin** on workspace/project (HCP UI, not K8s-style Roles in `.tf`) |
| **Run history / policy / triggers** | No | **Yes** |
| **Works with `cloud { }` block?** | **No** — not used for env switching on HCP | **This is the model** |
| **Expression in HCL** | `terraform.workspace` = CLI workspace name | Use **variables** (`var.environment`), not `terraform.workspace`, for HCP workspace name on remote runs |

### What they have in common

- **Goal:** run the **same (or similar) configuration** against **different** infrastructure without one state file for everything.
- **One state per “slot”:** one CLI workspace name → one state; one HCP workspace → one state.
- **Name collision:** both are called “workspace” in documentation — read the **context** (CLI command vs HCP UI / `cloud` block).

### What is different (exam favorites)

1. **CLI workspace = state file switch only.** HCP workspace = **platform** around that state.
2. **`terraform login` + `cloud`** → HCP workspaces. **`terraform workspace select`** → CLI workspaces (local or S3-style backend **without** replacing that with HCP’s workspace model).
3. **`TF_WORKSPACE` with `cloud` block** → selects **HCP** workspace name (when using tags), **not** a CLI workspace.
4. **Prod safety:** HCP gives permissions and review; CLI workspaces give a separate file and nothing else.

---

## Mental model (one diagram)

```text
Same root module (.tf files)
        |
        +-- CLI workspaces (backend local or S3)
        |       terraform workspace select dev  -->  state file A
        |       terraform workspace select prod -->  state file B
        |
        +-- HCP Terraform
                cloud { workspaces { name = "app-dev" } }   -->  HCP workspace app-dev (state + vars + runs)
                cloud { workspaces { name = "app-prod" } }  -->  HCP workspace app-prod
                (often separate cloud blocks OR tags + TF_WORKSPACE — not terraform workspace select)
```

---

## Which should you use?

| Situation | Typical choice |
|---|---|
| Solo learning, this study repo, local `terraform.tfstate` | **default** CLI workspace only; you may never run `workspace new` |
| Laptop + S3 backend, small team, no HCP | CLI workspaces **or** separate state keys / separate dirs |
| Team, CI, policy, remote runs, credentials in the platform | **HCP Terraform workspaces** — **not** CLI workspaces |
| Already using **`cloud { }`** | **HCP workspaces only**; ignore `terraform workspace` for environments |

---

## Related commands and docs

```bash
# CLI workspaces (6a) — not for HCP env switching when cloud is configured
terraform workspace list
terraform workspace show

# HCP — CLI still talks to the service after login
terraform login
# TF_WORKSPACE=my-hcp-ws terraform plan   # when cloud.workspaces uses tags
```

- [6a — local backend and CLI workspaces](06a-local-backend)
- [6c — S3 backend and workspace prefixes](06c-remote-backend)
- [8c — projects, variable precedence, run triggers](../08-hcp-terraform/08c-workspaces-and-projects)
- [8d — cloud block and confusion table](../08-hcp-terraform/08d-cli-integration)
- [cheatsheet](../cheatsheet.md#cli-workspaces-vs-hcp-terraform-workspaces)
