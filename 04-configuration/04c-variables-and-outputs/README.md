# 4c — Variables and outputs

Docs: [Variable block](https://developer.hashicorp.com/terraform/language/v1.12.x/block/variable), [output block](https://developer.hashicorp.com/terraform/language/v1.12.x/block/output), [variables tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables).

Variables are the inputs of a module. Outputs are the values it is willing to expose. The root module is the directory where you run Terraform. Its variables come from files, the environment, and CLI flags. Its outputs are what `terraform output` prints and what other configurations can read through remote state.

## Variable block

```hcl
variable "filename" {
  type        = string
  description = "File written next to this module."
  default     = "unit.txt"
  nullable    = false
  sensitive   = false
}
```

A variable with **no `default`** is **required**. If you do not supply a value, Terraform **errors** (during plan/validate, before apply can succeed).

| Module | How the caller must set a required variable |
|---|---|
| **Root** (where you run `terraform apply`) | `terraform.tfvars`, `*.auto.tfvars`, `TF_VAR_name`, `-var`, `-var-file` |
| **Child** | An argument on the parent’s **`module` block** with the same name as the child’s `variable` |

Omitting a required argument on `module "pet" { }` is the same class of error as forgetting a root variable with no default. `nullable = false` rejects an explicit `null`, which is different from omitting the variable (the default still applies when you omit it).

`description` is documentation. Tools and the Terraform Registry display it. It does not affect the plan.

## Optional variables: use `default`, not `optional()`

To make a **whole variable** optional for the caller, give it a **`default`**. The caller may omit it; Terraform uses the default.

```hcl
variable "filename" {
  type    = string
  default = "unit.txt"   # optional; falls back to unit.txt
}

variable "suffix" {
  type    = string
  default = ""           # optional; falls back to empty string
}
```

| Variable block | Caller must supply a value? |
|---|---|
| No `default` | **Yes** — required |
| `default = "unit.txt"` | **No** — optional |
| `default = ""` | **No** — optional (empty string is still a valid default) |
| `default = null` and `nullable = true` | **No** — optional; value may be `null` |

**`optional(...)` is not the way you mark a top-level variable optional.** The `optional` type modifier is only valid **inside an `object({ ... })` type** — usually to say that one **attribute** of an object-typed variable may be omitted. It does not apply to `type = string`, `type = list(string)`, and so on by itself.

```hcl
# Invalid — optional() cannot wrap the whole variable type
variable "region" {
  type = optional(string)
}

# Valid — optional attributes inside an object-typed variable
variable "service" {
  type = object({
    name = string
    port = optional(number, 8080)
    tags = optional(map(string), {})
  })
  default = {
    name = "api"
    # port and tags may be omitted; optional() supplies defaults for those keys
  }
}
```

Summary for the exam:

- **Optional variable** → `default` on the `variable` block (including `default = ""`).
- **Optional field inside an object variable** → `optional(type)` or `optional(type, default)` in the `object({ ... })` schema. Details: [4d](../04d-complex-types).

## Where values come from

Later sources override earlier ones:

1. `TF_VAR_filename` in the environment — sets `var.filename` only if `variable "filename" { }` exists; see [hcp-variables-and-tf-var.md](../../08-hcp-terraform/hcp-variables-and-tf-var.md)
2. `terraform.tfvars` if the file exists
3. `terraform.tfvars.json` if it exists
4. any `*.auto.tfvars` or `*.auto.tfvars.json`, in lexical filename order
5. `-var` and `-var-file` on the command line, in the order written

`terraform plan` loads `terraform.tfvars` by itself. `terraform plan -var-file=terraform.tfvars` loads it too. The official sample's answer is "all of the above."

```bash
export TF_VAR_filename=from-env.txt
terraform plan -var='filename=from-flag.txt'
```

The flag wins over the environment variable.

A `.tfvars` file is not automatically loaded just because it ends in `.tfvars`. Only `terraform.tfvars`, `terraform.tfvars.json`, and `*.auto.tfvars` are. Anything else needs `-var-file`. People name environment files `dev.auto.tfvars` so they load, or `dev.tfvars` so a human must opt in.

## Locals

```hcl
locals {
  path = "${path.module}/${var.filename}"
}
```

Locals are named expressions inside the module. They are not inputs, they are not outputs, and callers cannot set them. Use them to avoid repeating a transformation.

Longer write-up (variables as module inputs, locals as private derived values, **locals referencing other locals**, scope across modules): [locals-vs-variables.md](../locals-vs-variables.md).

## Outputs

```hcl
output "path" {
  description = "File Terraform manages."
  value       = local.path
  sensitive   = false
}
```

```bash
terraform output
terraform output -raw path
terraform output -json
```

### What `terraform apply` prints (outputs)

| Output location | Printed by `terraform apply`? |
|---|---|
| **Root module** `output` block | **Yes** (in the **Outputs:** footer; also `terraform output`) |
| **Child module** `output` block alone | **No** |
| **Child output re-exposed in root** `output` | **Yes** (the root `output` name is what the CLI shows) |

**Rule:** To surface **any** value to the CLI — whether it comes from a **child module**, a **resource attribute**, or a **local** — declare it as an **`output` in the root module**. Locals and resources are never printed as outputs by themselves; child outputs are only visible to the parent as `module.<name>.<output>` inside configuration until you copy them into a root `output`.

```hcl
locals {
  label = "prod-api"
}

module "pet" {
  source = "./modules/pet"
}

# Not printed: local.label, module.pet.name by itself at end of apply

output "label" {
  value = local.label
}

output "pet_name" {
  value = module.pet.name   # child output → root output → printed
}
```

**`terraform output`** without a module path lists the same **root** outputs stored in state. For debugging nested values, `terraform show -json` can include child module output data — not the normal operator workflow. Module boundaries: [5b](../../05-modules/05b-variable-scope).

Root outputs are stored in state and printed at the end of apply.

**Child modules:** the **only** way to pass data to the caller is an **`output`** block. The output’s `value` may come from a local, a resource attribute, or a variable, but the parent always reads `module.pet.name`, never `module.pet.local.*` or `module.pet.random_pet.this.id`. See [5b](../../05-modules/05b-variable-scope).

`sensitive = true` redacts the value in CLI output and some UI displays. It does **not** encrypt state or keep the value out of state when used as a normal argument. Prefer `TF_VAR_*`, `-var`, or gitignored var-files so secrets are not committed in `.tf` / `.tfvars`; use provider credential files or env for cloud auth. Full picture: [4h](../04h-sensitive-data).

## Precedence inside one module

Variables do not automatically flow into child modules. Outputs do not automatically become variables of the caller. You wire both by writing arguments and references. Scope is the whole of [5b](../../05-modules/05b-variable-scope).

## Apply

```bash
cd 04-configuration/04c-variables-and-outputs
terraform init
terraform plan
terraform plan -var-file=terraform.tfvars
```

Both plans use the same filename. Then override it:

```bash
terraform plan -var='filename=other.txt'
```
