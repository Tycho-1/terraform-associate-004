# 4h — Sensitive data, ephemeral values, write-only arguments, Vault

**New in 004:** ephemeral values and write-only arguments. `sensitive = true` and Vault sit in the same objective on the content list. The new part is what stays out of state. Index: [new-in-004.md](../../00-before-the-exam/new-in-004.md).

Docs: [Manage sensitive data](https://developer.hashicorp.com/terraform/language/v1.12.x/manage-sensitive-data), [ephemeral](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/ephemeral), [write-only arguments](https://developer.hashicorp.com/terraform/language/manage-sensitive-data/write-only), [sensitive variables tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables), [Vault provider](https://registry.terraform.io/providers/hashicorp/vault/latest/docs).

Terraform has to send a database password to a provider. It does not have to store that password in the plan and the state. 1.12 gives you three different mechanisms, and the exam expects you to know which one does what.

| Mechanism | Since | What it changes |
|---|---|---|
| `sensitive = true` | 0.14 / 0.15 | Redacts the value in CLI and UI output. The value is still stored in state and in the plan. |
| `ephemeral = true`, `ephemeral` blocks | 1.10 | The value is available during the run and is omitted from the plan and the state. |
| write-only arguments (`password_wo`) | 1.11 | The provider receives the value during apply. Terraform does not store it. A separate version argument is what the plan tracks. |

## What `sensitive = true` does and does not do

Marking a variable (or output) as **`sensitive`** only **redacts** its value from **Terraform CLI output** and some **UI displays** (plan/apply logs, default `terraform output`). It does **not**:

- encrypt the state file or the plan file
- generate or store the secret for you outside the configuration
- stop the value from appearing in **state** when that variable is used as a normal resource argument
- prevent someone from putting the secret **directly in `.tf` or `.tfvars`** if they choose to

If the password is written in code, referenced as `var.password`, or passed in and then assigned to a managed attribute, it can still end up in **state in plaintext**. `sensitive` is a **display** control, not a secrets manager.

**Keeping secret values out of committed configuration files** is a separate practice:

| Source | Typical use |
|---|---|
| `TF_VAR_name` environment variable | CI and laptops inject secrets at run time |
| `terraform plan -var='name=value'` | One-off; watch shell history and process lists |
| `-var-file` pointing at a **gitignored** file | Team-local secrets file |
| Provider **credential chain** (e.g. `AWS_ACCESS_KEY_ID`, shared credentials file, instance profile) | Cloud API auth without putting keys in HCL |
| HCP Terraform **workspace environment variables** or **dynamic credentials** (`TFC_AWS_*`, …) | Cloud API auth on **remote** workers — see [provider-credentials.md](../../08-hcp-terraform/provider-credentials.md) |

Those paths supply values **without** hard-coding them in tracked `.tf` files. They do **not** by themselves keep a value out of state if you still pass it into a normal resource argument. For that, use **ephemeral** values or **write-only** arguments (below).

## The sample question, answered precisely

"Usernames and passwords referenced in the Terraform code, even as variables, will end up in plain text in the state file."

For an ordinary variable, including one marked `sensitive`, that is true. State is JSON on disk or in a backend. The `sensitive` flag tells Terraform to print `(sensitive value)` instead of the string. Anyone who can read the state can read the password.

Ephemeral variables and write-only arguments are the cases that do not land in state. If a question says only "sensitive variable", the value is in state. If it says "ephemeral" or "write-only", the value is omitted.

## Where a sensitive value may go

Once a value is sensitive, Terraform tracks that mark through expressions. You can use it in a resource argument. You can export it from an output only if that output is also `sensitive`. You cannot drop it into a plain output; Terraform errors rather than print it.

`nonsensitive(var.password)` strips the mark. That is a decision to reveal the value. It does not decrypt anything, because nothing was encrypted.

Root outputs marked sensitive are redacted by `terraform output` and shown by `terraform output -raw <name>` and `terraform output -json`.

## Ephemeral values

Four ways to get one:

- `ephemeral = true` on a variable
- `ephemeral = true` on a child module output
- an `ephemeral` block (an ephemeral resource)
- a write-only argument, which is ephemeral from the perspective of state

An ephemeral value may be used in another ephemeral context:

- another ephemeral variable or ephemeral output
- an `ephemeral` resource
- a write-only argument
- a `provider` block
- a provisioner or a provisioner connection

Using it in a normal resource argument is an error. That error is what keeps it out of state: there is no attribute slot that would persist it.

```hcl
variable "session_token" {
  type      = string
  ephemeral = true
}

ephemeral "random_password" "db" {
  length  = 20
  special = false
}
```

This folder generates an ephemeral password and passes its length through a `local-exec` provisioner, which is an allowed context. The password string is not an attribute of `terraform_data.announce` and it is not in `terraform.tfstate`.

A normal output cannot return that password or even `length(...)` of it. Any expression that touches an ephemeral value becomes ephemeral, and a root output is stored in state, so Terraform rejects the assignment. That error is the feature working.

Ephemeral variables are set the same way as other variables (`TF_VAR_`, `-var`). They are not read back from state on the next run, because they were never written there. Each run needs the value supplied again. That is what you want for a short-lived token.

## Write-only arguments

Providers opt in by defining arguments whose names end in `_wo`, plus a companion version:

```hcl
resource "aws_db_instance" "app" {
  username            = "app"
  password_wo         = ephemeral.random_password.db.result
  password_wo_version = 1
}
```

`password_wo.tf.example` is that pattern. It is not applied from this repo.

Terraform sends `password_wo` to the provider and then discards it. It cannot show a diff for a value it does not store, and it cannot notice that you edited the password. You increment `password_wo_version` when you want the provider to apply the current write-only value again. The version is a normal argument, stored in state, so the plan shows `~` on the version.

Write-only arguments accept ephemeral values and ordinary values. Prefer ephemeral, so the password is not also sitting in a variable default or a tfvars file that gets copied into a plan.

Some resources add a write-only attribute you can read back into an ephemeral context (`secret_string_wo` on a secrets manager version, and similar). The read result is ephemeral too.

## Vault

Vault is HashiCorp's secrets manager. Terraform's Vault provider reads and writes Vault. A common pattern is a data source that reads a secret at plan time and feeds it to another resource:

```hcl
data "vault_generic_secret" "db" {
  path = "secret/data/app"
}

resource "aws_db_instance" "app" {
  password = data.vault_generic_secret.db.data["password"]
}
```

That data source result is stored in state, sensitive or not. Reading from Vault did not solve state exposure; it solved "where does the human keep the secret." To keep the password out of Terraform state as well, read it with an ephemeral resource or an ephemeral data flow and pass it to a write-only argument.

Vault itself is not required knowledge beyond that relationship: Terraform is not a secrets manager, Vault is, and the provider is how configuration consumes Vault.

## What to do in practice

- Mark variables and outputs `sensitive` so logs and plan UI do not echo them.
- Keep state in a remote backend with access control. See [6c](../../06-state/06c-remote-backend).
- Prefer ephemeral values and write-only arguments for passwords and session tokens on Terraform 1.11+.
- Do not put secrets in `-var` on a shared CI log if you can use an environment variable or an ephemeral read.
- Do not commit `terraform.tfstate`, plan files, or crash logs.

## Apply

```bash
cd 04-configuration/04h-sensitive-data
terraform init
terraform apply
terraform output
terraform state list
```

`terraform output` prints `token_is_sensitive = <sensitive>`. Open `terraform.tfstate` and the demo token is there in plaintext, because that output is only marked sensitive. `terraform state list` shows `terraform_data.announce` and does not show `ephemeral.random_password.db` as a managed resource. State may record that address under the managed resource's dependencies. It does not record the generated password. The `local-exec` line is suppressed on purpose when the command contains an ephemeral value, so the password is not printed either.
