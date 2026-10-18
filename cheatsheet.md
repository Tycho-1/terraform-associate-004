# Cheat sheet

One page for later, when you already know the topics and need the syntax. The objective folders explain why each line exists.

## Workflow

```bash
terraform fmt -recursive          # rewrite .tf to canonical style
terraform fmt -check -recursive   # exit 3 if a file would change (CI)
terraform init                    # providers, modules, backend
terraform init -upgrade           # newest versions allowed by constraints
terraform validate                # syntax and types, no API calls
terraform plan                    # refresh state, print a diff, change nothing in the cloud
terraform plan -out=tfplan        # save the exact plan
terraform apply                   # prompt, then create/update/destroy, then write state
terraform apply tfplan            # apply a saved plan, no prompt
terraform apply -auto-approve
terraform destroy                 # same as: terraform apply -destroy
terraform plan -refresh-only      # preview state updates from drift; does NOT write state
terraform apply -refresh-only     # write drift into state; do not change infrastructure
terraform plan -replace=ADDR      # plan a forced replace (preview)
terraform apply -replace=ADDR     # destroy+create that instance this run (replaces taint)
terraform graph                   # dependency graph in DOT
terraform console                 # REPL: evaluate expressions (init; apply for resource attrs)
terraform test                    # run tests/*.tftest.hcl (plan/apply + assert)
terraform test -filter=name       # subset of runs
```

`terraform console` does not change infrastructure or state. It uses the current configuration and state. See [07d-terraform-console](07-maintain/07d-terraform-console).

`terraform test` runs configuration tests. See [07e-terraform-test](07-maintain/07e-terraform-test).

Plan symbols: `+` create, `-` destroy, `~` update in place, `-/+` destroy then create, `+/-` create then destroy (`create_before_destroy`).

## Commands that refresh state

`terraform plan` and `terraform apply` refresh state unless you pass `-refresh=false`. `terraform validate`, `terraform fmt`, and `terraform output` do not refresh. `terraform refresh` still exists and is superseded by `terraform apply -refresh-only`.

| Command | `.tf` | Real infra | Changes state |
|---|---|---|---|
| `plan` | Yes | Yes (refresh) | No infra change |
| `apply` | Yes | Yes | Yes |
| `plan -refresh-only` | No | Yes | No (preview) |
| `apply -refresh-only` | No (no config-driven changes) | Yes | Yes |
| `state rm` | No | No | Yes |

Full matrix: [commands-config-infra-state](03-core-workflow/commands-config-infra-state.md).

## Files

| File | Commit it? | Role |
|---|---|---|
| `*.tf` | yes | configuration |
| `.terraform.lock.hcl` | yes | pinned provider versions and hashes |
| `.terraform/` | no | downloaded providers and modules |
| `terraform.tfstate` | no | mapping of config to real objects, often contains secrets |
| `*.tfvars` | only if it has no secrets | variable values |
| `tfplan` | no | saved plan, can contain secrets |
| `*.tf.json` | yes | same configuration language in JSON |

Variable values, later sources win:

1. `TF_VAR_name` environment variables
2. `terraform.tfvars`
3. `terraform.tfvars.json`
4. `*.auto.tfvars` and `*.auto.tfvars.json`, lexical filename order
5. `-var` and `-var-file`, in the order you write them

`terraform plan` already loads `terraform.tfvars`. Passing `-var-file=terraform.tfvars` as well is redundant and still correct.

## Version constraints

```hcl
terraform {
  required_version = ">= 1.12.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

| Constraint | Meaning |
|---|---|
| `= 1.2.3` | exactly 1.2.3 |
| `>= 1.2.0` | 1.2.0 or newer |
| `~> 1.2` | `>= 1.2.0`, `< 2.0.0` |
| `~> 1.2.3` | `>= 1.2.3`, `< 1.3.0` |

`required_version` constrains the Terraform binary. `required_providers.version` constrains the plugin. The lock file records the exact plugin that `init` selected. Providers are **compiled binaries** only — not built from source at `init` time.

`terraform init` installs providers from the public registry by default. Enterprises may use a **private registry** (HCP Terraform), a **filesystem** or **network mirror**, or a **plugin cache** (`TF_PLUGIN_CACHE_DIR`) so installs work offline, stay on approved builds, or run faster. That is CLI config (`~/.terraformrc`), not a block in `.tf`. Details: [2a](02-fundamentals/02a-provider-versions).

## Addresses

```hcl
var.name
local.name
random_pet.this.id              # managed resource — no resource. prefix
data.http.index.status_code     # data source — data. is required
module.pet.name
random_pet.this[0].id          # count
random_pet.this["web"].id      # for_each
ephemeral.random_password.db.result
```

`resource.aws_instance.web.id` is **invalid**. Use `aws_instance.web.id`. Data sources always use `data.<type>.<name>.<attr>`. Details: [04b](04-configuration/04b-references).

## Providers and aliases

```hcl
provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "dr"
  region = "eu-west-1"
}

resource "aws_instance" "backup" {
  provider = aws.dr
  # ...
}
```

**Provider is inferred from the type name:** the substring before the first `_` in the type is the provider local name. `aws_vpc` → `aws`. `azurerm_resource_group` → `azurerm`. `random_pet` → `random`. Same for `data "aws_ami"` and `ephemeral "random_password"`. The second label (`shared` in `aws_vpc.shared`) is only your resource name.

A resource uses the default `provider "<name>"` with no `alias`. `provider = aws.dr` selects an alias. `provider = "aws.dr"` as a string is invalid. Aliases are not inherited by child modules; pass them with the `providers` map on the `module` block.

## Common data sources (read-only; use `data.` in expressions)

| Type | Fetches |
|---|---|
| `aws_ami` | AMI id / image metadata |
| `aws_vpc` (etc.) | Existing cloud object attributes |
| `aws_iam_policy_document` | Computed policy JSON |
| `terraform_remote_state` | **Outputs** from another state |
| `local_file` / `http` | File or HTTP body |

Templates: prefer `templatefile()` over legacy `data "template_file"`. More: [4a](04-configuration/04a-resources-and-data).

## Resource vs data vs ephemeral

```hcl
resource "local_file" "unit" {          # Terraform creates and tracks this
  filename = "${path.module}/unit.txt"
  content  = "hello"
}

data "local_file" "unit" {              # Terraform reads this, does not create it
  filename = local_file.unit.filename
}

ephemeral "random_password" "db" {      # exists for this run only, omitted from state
  length = 16
}
```

## Variables, locals, outputs

```hcl
variable "name" {
  type        = string
  description = "Short name used in tags."
  default     = "demo"

  validation {
    condition     = length(var.name) > 2
    error_message = "Name must be longer than 2 characters."
  }
}

locals {
  name = "${var.name}-${random_id.suffix.hex}"
}

output "name" {
  value       = local.name
  description = "Name written into the file."
  sensitive   = false
}

output "pet_name" {
  value = module.pet.name   # re-export child output for apply / terraform output
}
```

| Printed by `apply` / `terraform output` | |
|---|---|
| Root `output` | Yes |
| Child `output` alone | No |
| Root `output` with `value = module.child.x` | Yes |

**Rule:** CLI-visible values need a **root** `output` (from child module, local, or resource). [4c](04-configuration/04c-variables-and-outputs).

Variables are **inputs** (tfvars, `TF_VAR_*`, `-var`, parent `module` args). Locals are **private** named expressions inside one module; use `var` and `local` in locals (no circular `local.a` ↔ `local.b`). See [locals-vs-variables.md](04-configuration/locals-vs-variables.md).

**Optional variable:** `default` on the `variable` block (e.g. `default = ""`). **`optional(type)`** only inside `object({ ... })`, not `type = optional(string)` alone. [4c](04-configuration/04c-variables-and-outputs), [4d](04-configuration/04d-complex-types).

## Types

```hcl
string  number  bool
list(string)  set(string)  map(string)
tuple([string, number])
object({ name = string, ports = list(number) })
optional(string, "default")
any
```

`list` and `tuple` are ordered. `set` is unique and unordered. `map` keys are strings and every value has the same type. `object` attributes each have their own type.

## count, for_each, dynamic, for

```hcl
resource "random_pet" "counted" {
  count  = 2
  length = 2
}

resource "random_pet" "named" {
  for_each = toset(["web", "api"])
  length   = 2
}

locals {
  upper  = [for s in var.names : upper(s) if s != ""]           # [...] → list
  by_key = { for o in var.objects : o.key => o.value }        # { => } → map
  by_id  = { for p in random_pet.named : p.id => p.length }
}

# splat (count / for_each resources only) → list
random_pet.named[*].id

dynamic "data_disk" {          # nested block type to repeat
  for_each = var.data_disks    # dynamic always uses for_each (not count)
  content {
    name         = data_disk.value.name   # .value / .key on iterator name
    disk_size_gb = data_disk.value.disk_size_gb
  }
}
```

`count` / `for_each` on a **resource** → multiple resources. **`dynamic` + `for_each`** → repeat a **nested** block inside one resource from a variable. `for` in `locals` only computes values. See [04e](04-configuration/04e-expressions-and-functions).

`count` addresses are integers. Inserting an item at the front shifts every index and Terraform plans replacements. `for_each` keys stay put. Use `for_each` when the identity of each instance matters.

## Dependencies and lifecycle

```hcl
resource "terraform_data" "second" {
  depends_on = [terraform_data.first]

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [input]
    replace_triggered_by  = [terraform_data.first]

    precondition {
      condition     = length(var.name) > 0
      error_message = "Name must be set before this resource is planned."
    }

    postcondition {
      condition     = self.output != null
      error_message = "terraform_data produced no output."
    }
  }
}
```

An expression reference (`random_pet.this.id`) is an implicit dependency. `depends_on` is the explicit one, for relationships Terraform cannot see from references. `depends_on` is **not** nested inside `lifecycle`. `create_before_destroy` creates the replacement first and shows as `+/-` in the plan.

All valid `lifecycle` arguments in one note: [lifecycle-block-reference.md](04-configuration/lifecycle-block-reference.md).

## Custom conditions

| Block | When it runs | Failure |
|---|---|---|
| `validation` on a variable | while building the plan | error, run stops |
| `precondition` | before that resource instance’s create/update/destroy; per `count`/`for_each` instance; can defer until apply-time values known | error, run stops |
| `postcondition` | after apply/read on that object; failure blocks dependents | error, run stops |
| `check` / `assert` | last step of plan or apply (after resources planned or provisioned) | warning, run continues — **only** custom condition that is intentionally non-blocking; health/monitoring, not strict enforcement |

## Sensitive, ephemeral, write-only

```hcl
variable "token" {
  type      = string
  sensitive = true   # redacts CLI output; still stored in state
}

variable "session" {
  type      = string
  ephemeral = true   # omitted from plan and state
}

resource "aws_db_instance" "app" {
  password_wo         = ephemeral.random_password.db.result
  password_wo_version = 1   # bump this to rotate; the password itself is not in state
}
```

`sensitive` redacts CLI/UI display only; values can still sit in state, plans, and hard-coded `.tf`. Use `TF_VAR_*`, `-var`, gitignored var-files, and provider credential env/files to keep secrets out of committed config — that is separate from keeping them out of state (ephemeral / write-only). [4h](04-configuration/04h-sensitive-data). Write-only arguments accept either ephemeral or normal values. Terraform cannot diff a write-only value, so the companion `_wo_version` is what the plan tracks.

## State commands

```bash
terraform state list
terraform state show random_pet.this
terraform state mv random_pet.this random_pet.renamed
terraform state rm random_pet.orphaned          # drop from state only; does NOT destroy cloud object
terraform state pull > terraform.tfstate.backup
terraform force-unlock LOCK_ID                  # last resort: lock stuck after crash; not normal wait
```

Prefer a `moved` block over `terraform state mv`, and a `removed` block over `terraform state rm`, so the change is reviewed in a plan.

**`moved`:** rename resource, move into module, refactor without destroy — **not** for changing **resource type** (that needs replace). [6d](06-state/06d-drift-and-refactor).

```hcl
moved {
  from = random_pet.this
  to   = random_pet.renamed
}

removed {
  from = random_pet.orphaned

  lifecycle {
    destroy = false
  }
}
```

## Import

```hcl
import {
  to = aws_instance.web
  id = "i-0123456789abcdef0"
}
```

```bash
terraform plan -generate-config-out=generated.tf
terraform import aws_instance.web i-0123456789abcdef0
```

The CLI form requires the `resource` block to already be in configuration. The `import` block can generate it. Import updates state. It does not change the live object.

## Backends

**Remote state:** inside `terraform { }`, use **either** `backend "<type>" { }` (S3, GCS, `azurerm`, …) **or** `cloud { }` (HCP Terraform) — **not both**. Legacy HCP: `backend "remote"`. Then `terraform init` / `-migrate-state`.

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }

  # backend "s3" { ... }     # self-managed remote state
  # cloud { organization = "..." workspaces { name = "..." } }  # HCP remote state

  # One backend OR cloud per configuration. backend args are static (no var/local).
}
```

```bash
terraform init -migrate-state    # copy state into a new backend
terraform init -reconfigure      # adopt a new backend and discard the previous local pointer
terraform init -backend-config=backend.hcl
```

**Local → remote:** shared team state, locking, server-side encryption (S3/GCS/Azure), durability/versioning, IAM access — not remote execution unless HCP Terraform. [6c](06-state/06c-remote-backend).

**State locking:** one state-writing run holds the lock; another state write is **blocked** until release. **Not guaranteed on all backends** — verify yours before team/CI use. [6b](06-state/06b-locking).

## Modules

```hcl
module "pet" {
  source  = "./modules/pet"          # local path
  # source  = "terraform-aws-modules/vpc/aws"
  # version = "5.13.0"               # registry modules only
  name = var.name
}

output "pet_name" {
  value = module.pet.name            # only declared outputs are visible
}
```

Child modules do not see the caller's variables. Pass every input as an argument. **Only `output` blocks export data to the caller** (`module.pet.id`), whether the value is built from a local, resource, or variable — never `module.pet.local.*` or `module.pet.aws_instance.web.id`.

| Pin | Required? |
|---|---|
| Registry `module` `version` | No (optional; latest if omitted) — **invalid** on local/Git |
| `required_providers` `version` | No (optional) — use constraints + lock file anyway |

**False on exams:** “Registry modules **require** `version`.” Pin in production anyway. [5d](05-modules/05d-module-versions), [2a](02-fundamentals/02a-provider-versions).

## Logs

```bash
TF_LOG=TRACE TF_LOG_PATH=./terraform.log terraform plan
```

Levels: `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`. `TRACE` is the most verbose. Logs can contain secrets. `TF_LOG_CORE` and `TF_LOG_PROVIDER` set the two streams separately.

## CLI workspaces vs HCP Terraform workspaces

**CLI workspace** (`terraform workspace new/select`) — multiple **state files** for **one** root module + backend; **no** HCP variables, RBAC, or remote runs. Local: `terraform.tfstate.d/<name>/`. **`terraform.workspace`** in HCL = CLI name.

**HCP workspace** — hosted object (one state + vars + runs + policy + creds); bind with **`cloud { }`**, not `terraform workspace select`. With **`cloud`**, env switching = different HCP workspace / **`TF_WORKSPACE`**; **`terraform.workspace` is usually `"default"`** on remote runs.

Full comparison: [cli-workspaces-vs-hcp-workspaces.md](06-state/cli-workspaces-vs-hcp-workspaces.md).

**HCP RBAC:** create **HCP teams** per org team; grant **Read/Plan/Write/Admin** at **org**, **project** (inherits to all workspaces in project), or **workspace**. Prefer **project** for grouped stacks; “plan+apply” = **Write**. [8b](08-hcp-terraform/08b-collaboration-governance#best-practice-one-hcp-team-per-real-world-team).

## HCP Terraform

**`cloud` block:** max **1** per configuration; **`cloud` + `backend`** forbidden; max **1** `backend` if not using `cloud`. Several HCP workspaces → **one** `cloud` with `workspaces { tags = [...] }` or `project`, not two `cloud` blocks. **`cloud`** → remote **state** + default remote **operations** (plan/apply on HCP); **`backend "s3"`** → remote state only, apply still local. [8d rules](08-hcp-terraform/08d-cli-integration/cloud-block-rules.md#cloud-vs-backend-s3--remote-state-vs-remote-operations).

```hcl
terraform {
  cloud {
    organization = "example-org"

    workspaces {
      name = "networking"
      # project = "platform"
      # tags    = ["env:dev", "team:net"]  # pick one: name, tags, or project
    }
  }
}
```

```bash
terraform login
terraform init     # migrates state when you add the cloud block to an existing config
terraform plan     # remote execution by default
terraform apply
```

Variable precedence inside HCP Terraform, highest first: workspace variables, then variable sets on that workspace, then variable sets on its project, then organization-wide variable sets.

**HCP variable kinds:** UI **Terraform variable** → `var.x`; UI **environment variable** → process env (`AWS_*`, `TFC_*`). **`TF_VAR_x`** (env) **sets** `var.x` but does **not** define `variable "x"` in HCL. [hcp-variables-and-tf-var.md](08-hcp-terraform/hcp-variables-and-tf-var.md).

Policy enforcement levels: advisory (warn, continue), soft-mandatory (fail unless an authorized user overrides), hard-mandatory (fail, no override). **Sentinel/OPA** run on the **plan** before apply (e.g. S3 private + SSE) — [sentinel-s3-bucket-policy.md](08-hcp-terraform/08b-collaboration-governance/sentinel-s3-bucket-policy.md).

**Health assessment** (HCP Terraform): scheduled background check for correctness without queuing a normal run. **Drift detection** — real infra vs state (out-of-band changes). **Continuous validation** — re-runs `check` blocks (HTTP 200, cert expiry, …). Findings alert; drift does not auto-fix; failed checks still do not block apply. [8b](08-hcp-terraform/08b-collaboration-governance#health-assessments), [4g](04-configuration/04g-custom-conditions).

**HCP vs CLI+S3:** state **versions** + **run history**, **remote execution** (`cloud`), **variable sets** (Terraform + env vars) — platform features, not plain `backend "s3"`. [hcp-vs-open-source-cli.md](08-hcp-terraform/hcp-vs-open-source-cli.md).

**Projects:** org → **project** → workspace; group stacks (prod vs dev); **RBAC** + variable/policy sets at project scope inherit to all workspaces in the project. [8c](08-hcp-terraform/08c-workspaces-and-projects#projects).

**Credentials:** `terraform login` = HCP API token only. **Remote** runs use workspace **environment** vars (`TFC_AWS_PROVIDER_AUTH` + role ARN, or `AWS_ACCESS_KEY_ID`, …) on the worker — not laptop `~/.aws`. No keys in `provider` HCL. `TF_VAR_*` ≠ cloud auth. [provider-credentials.md](08-hcp-terraform/provider-credentials.md).
