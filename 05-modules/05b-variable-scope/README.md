# 5b — Variable scope inside modules

Docs: [Module composition](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/develop/composition), [manage values in modules](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/develop/structure).

Each module has its own variables, locals, resources, and outputs. A child module does not see the caller's variables. The caller does not see the child's resources.

```text
root module                         child module "pet"
-----------------------------       -----------------------------
var.prefix  ---- argument ------>   var.prefix
                                    local.filename
                                    random_pet.this
                                    output.name  -- reference --> module.pet.name
```

You pass inputs as arguments on the `module` block. The argument names are the child module's variable names.

```hcl
module "pet" {
  source = "./modules/pet"
  prefix = var.prefix
}
```

Inside `modules/pet`, that value is `var.prefix`. There is no `var.prefix` in the child unless the child declares `variable "prefix"`. An extra argument the child does not declare is an error.

**Required child variables:** A variable **without a `default`** is **required**. If the caller does not pass it as an argument on the **`module` block**, Terraform errors at plan time (there is nothing to infer). Optional child inputs use `default` on the child’s `variable` block; then the caller may omit that argument.

```hcl
# child: variable "prefix" { type = string }   # no default → required

module "pet" {
  source = "./modules/pet"
  # prefix = "web"   # omitted → error: required variable not set
}
```

At the **root** module, the same rule applies: no `default` means you must supply the value via `terraform.tfvars`, `TF_VAR_*`, `-var`, and so on.

## What crosses the boundary

| Object | Visible to the caller? |
|---|---|
| Child variable | only as an argument the caller sets |
| Child local | no |
| Child resource attribute | no |
| Child output | yes, as `module.<name>.<output>` |
| Caller variable | no, unless passed as an argument |
| Root `terraform.workspace` | the workspace name is global; the expression works in every module |

Providers are not inherited when you use aliases. Pass them with `providers = { aws = aws.dr }`. The default (unaliased) provider configuration is inherited. See [2c](../../02-fundamentals/02c-multiple-providers).

## Outputs are the public API

**Rule:** The **only** way to pass data **out** of a module to its caller is **`output` blocks** — whether the exported value comes from a **local**, a **resource attribute**, or a **variable** inside the child.

```hcl
# child module
locals {
  label = "${var.environment}-${var.name}"
}

resource "random_pet" "this" {
  length = 2
  prefix = local.label
}

output "pet_id" {
  value = random_pet.this.id          # from a resource
}

output "label" {
  value = local.label                 # from a local
}

output "environment" {
  value = var.environment             # pass-through from an input
}
```

```hcl
# caller (root or parent module)
module "pet" {
  source = "./modules/pet"
  # ...
}

resource "local_file" "unit" {
  content = module.pet.pet_id         # valid
}

# module.pet.random_pet.this.id       # invalid — no such reference
# module.pet.local.label              # invalid
```

There is no `module.pet.local.*` and no `module.pet.<resource_type>.*`. If the caller needs a value, the child module must **`output`** it.

A module author chooses which outputs to expose. That boundary is what lets you rename internal resources or locals without breaking callers, as long as **output names** and meanings stay stable.

Sensitive and ephemeral marks cross the boundary with the value. A sensitive output must be received by a caller who treats it as sensitive. An ephemeral output exists only on a child module (`ephemeral = true` on that `output`) and the caller can only use it in an ephemeral context.

## Nested modules

A child can call its own children. Scope rules are the same at every level. The root module is not special except that its variables come from tfvars and CLI flags, and its outputs are stored in the root state for `terraform output` and `terraform_remote_state`.

**CLI outputs are root-only.**

| Output location | Printed by `terraform apply`? |
|---|---|
| Root `output` | Yes |
| Child `output` only | No |
| Child value in root `output` (`value = module.child.x`) | Yes |

**Rule:** surface anything to the CLI with a **root** `output` (from `module.*`, `local.*`, or a resource attribute). See [4c](../../04-configuration/04c-variables-and-outputs).

Child **locals** never cross the module boundary; only **variables** (in) and **outputs** (out) do. See [locals-vs-variables](../../04-configuration/locals-vs-variables.md).
