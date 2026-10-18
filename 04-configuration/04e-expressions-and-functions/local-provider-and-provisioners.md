# Local provider, `terraform_data`, and provisioners

Study note for “run on my machine” patterns in this repo (`local`, `random`, `terraform_data`, and `local-exec`). Not a separate exam objective; it clarifies names people confuse on practice questions.

## Three different ideas

| Name | What it is |
|---|---|
| **`hashicorp/local` provider** | A real provider plugin. Resources like `local_file` manage **files on the Terraform host**. |
| **`local-exec` provisioner** | Not a provider. A **hook** on another resource that runs a **shell command on the Terraform host** during apply. |
| **`remote-exec` provisioner** | Same idea, but runs over **SSH on a remote machine** (usually right after that machine was created). |

There is no resource type called `local_exec`. Exam text usually means **`provisioner "local-exec"`** or the **`local`** provider family.

## `hashicorp/local` provider

Install it in `required_providers` and run `terraform init`, like any other provider.

| Resource | Purpose |
|---|---|
| `local_file` | Create or update a file; `content` or `source` / `content_base64`. Used in [main.tf](main.tf) for `rendered.txt`. |
| `local_sensitive_file` | Same idea; provider treats content as sensitive in logs. |
| `local_file` with `source` | Copy from an existing file instead of inline `content`. |

**State:** Terraform stores the arguments it manages (including file content unless you use patterns that avoid it). **Drift** is detected on refresh: if someone edits the file outside Terraform, the next plan can show an update.

**Limits:** Only useful when writing on the **Terraform runner** is intentional. HCP Terraform **remote** execution runs on HashiCorp’s worker, not your laptop — a `local_file` there writes on the worker filesystem, which is usually wrong for production. See [08a](../../08-hcp-terraform/08a-create-infrastructure).

## `terraform_data` (built-in, no extra provider)

`terraform_data` is a **first-class resource** in Terraform core (not `hashicorp/null`). This repo uses it for lifecycle and dependency demos:

- [04f-dependencies-and-lifecycle](../04f-dependencies-and-lifecycle)
- [04g-custom-conditions](../04g-custom-conditions)
- [04h-sensitive-data](../04h-sensitive-data) (with a provisioner)
- [labs/local-stack](../../labs/local-stack)

It holds arbitrary `input` / `output` and supports **`triggers_replace`** to force replacement when a value changes. It does **not** by itself run shell commands unless you attach a provisioner.

Prefer `terraform_data` over legacy **`null_resource`** for “placeholder” resources in new config; exams may still show `null_resource` in older snippets.

## Provisioners: `local-exec` and `remote-exec`

Provisioners live **inside** a `resource` block:

```hcl
resource "terraform_data" "example" {
  provisioner "local-exec" {
    command = "echo applied"
  }
}
```

| Provisioner | Runs where | Typical use (still a last resort) |
|---|---|---|
| `local-exec` | Machine running Terraform | One-off script, notify CI, glue during apply |
| `remote-exec` | Remote host via SSH | Bootstrap right after `aws_instance` (legacy pattern) |

**HashiCorp’s guidance:** provisioners are a **last resort**. They run **during apply**, not on every plan. Terraform does **not** model what the script created (packages, files from `curl`, etc.), so drift and idempotency are your problem. Prefer cloud-init, configuration management, images (Packer), or a **custom provider** for real APIs. See [01a](../../01-infrastructure-as-code/01a-what-is-iac) and [terraform-and-ansible](../../terraform-vs-iac/ansible/terraform-and-ansible.md).

**Destroy:** `when = destroy` runs a provisioner on destroy. Easy to get wrong; know it exists for the exam, avoid relying on it in design.

**Ephemeral values:** In 004, some values may only be used in certain contexts. [04h](../04h-sensitive-data) uses `local-exec` with an ephemeral password — allowed context; the secret is not stored as a resource attribute.

## Quick comparison

```text
local_file          -> provider manages a file; content in state (unless sensitive_file / careful design)
terraform_data      -> managed object in state; good for triggers, depends_on, no file by default
local-exec          -> side-effect script; script side effects NOT fully tracked in state
remote-exec         -> script on remote VM; needs connectivity and SSH; same tracking limits
```

## What the Associate exam tends to test

- **`terraform init`** installs the **`local`** provider when `required_providers` asks for it.
- Resource type **`local_file`** maps to provider **`local`**, not to `local-exec`.
- Provisioners **do not** replace a provider for a proprietary API; use a **custom provider** instead ([2b](../../02-fundamentals/02b-how-providers-work)).
- **`local-exec` on remote runs** does not see files on your laptop unless they were uploaded with the configuration bundle.

## Examples in this repo

| Path | Pattern |
|---|---|
| [04e/main.tf](main.tf) | `local_file` + expressions |
| [04f](../04f-dependencies-and-lifecycle) | `terraform_data` + `depends_on` / lifecycle |
| [04h](../04h-sensitive-data) | `terraform_data` + `local-exec` + ephemeral |
| [03-core-workflow/lab](../../03-core-workflow/lab) | `local_file` + `random_pet` workflow |
