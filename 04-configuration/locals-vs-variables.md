# Locals vs variables

Study note for objective **4c** (inputs/outputs) and **5b** (module scope). The runnable lab is [04c-variables-and-outputs](04c-variables-and-outputs). Docs: [variable block](https://developer.hashicorp.com/terraform/language/v1.12.x/block/variable), [locals](https://developer.hashicorp.com/terraform/language/v1.12.x/values/locals).

## What `locals` are for

A **`locals` block** gives **names to expressions** inside **one module**. You use locals when:

- The same computed value appears in **several** resources, outputs, or other locals (DRY).
- You want a **single place** to change a convention (path prefix, tag map, name suffix).
- The value is **derived** from variables, resources, data sources, or functions — not something a human should type again in five arguments.

```hcl
variable "filename" {
  type    = string
  default = "unit.txt"
}

locals {
  path = "${path.module}/${var.filename}"
}

resource "local_file" "unit" {
  filename = local.path
  content  = var.content
}
```

Here `local.path` is **this module’s** idea of “where the file lives.” Every resource that needs that path should use `local.path`, not repeat `"${path.module}/${var.filename}"`.

Locals are **not** a second kind of input. Nobody runs `terraform apply -local=...`. Locals exist only in `.tf` files and are evaluated during planning.

You may have **multiple** `locals { }` blocks in one module; Terraform merges them into one map of local values.

## Locals referencing other locals

A local can use **`local.<name>`** to read another local in the **same module**, as long as there is **no circular dependency** (A depends on B depends on A). Terraform evaluates locals in dependency order.

```hcl
locals {
  region      = "eu-central-1"
  environment = "prod"

  name_prefix = "${local.environment}-${local.region}" # references other locals
  full_name   = "${local.name_prefix}-app"              # references another local
}
```

| Reference | Value |
|---|---|
| `local.name_prefix` | `"prod-eu-central-1"` |
| `local.full_name` | `"prod-eu-central-1-app"` |

Use those names in resources, outputs, and other locals:

```hcl
resource "local_file" "unit" {
  filename = "${path.module}/${local.full_name}.txt"
  content  = "region=${local.region}\n"
}

output "app_name" {
  value = local.full_name
}
```

The same rules apply when locals mix **variables** and **other locals**: `name_prefix` could be `"${var.environment}-${local.region}"` if `region` were still a local and `environment` came from `var.environment`.

**Invalid:** `local.a = local.b` and `local.b = local.a` — Terraform reports a cycle. **Valid:** a chain `local.c → local.b → local.a` or locals that only reference `var.*` and resources.

## What `variable` blocks are for

A **`variable` block** declares a **module input**: a value the **caller** is allowed to supply.

| Who runs Terraform | Who sets variables |
|---|---|
| **Root module** (the directory where you run `terraform apply`) | `terraform.tfvars`, `*.auto.tfvars`, `TF_VAR_*`, `-var`, `-var-file` |
| **Child module** | The parent’s `module` block arguments |

```hcl
module "pet" {
  source = "./modules/pet"
  prefix = var.prefix   # root var -> child var
}
```

Variables are the **public knobs** on a module. They carry `type`, `description`, `default`, `validation`, and `sensitive`. The Registry and `terraform-docs` show them as the module API.

## Variable vs local — the distinction

| | **Variable** | **Local** |
|---|---|---|
| **Role** | Input from outside the module | Internal named expression |
| **Set by** | Caller, tfvars, env, CLI (root) or parent `module` args (child) | Only in HCL (`locals { ... }`) |
| **Visible outside module** | Yes — as an argument you must pass (or default) | **No** — private to the module |
| **Typical content** | Environment name, region, instance size, feature flags | Paths, merged tags, formatted names, `templatefile` result |
| **Can reference** | Other variables (via `var.`), not resources in validation in some cases | Variables, resources, data, other locals, functions |
| **Exam “direction”** | **Into** the module | **Inside** the module only |

**Variables can feed locals; locals do not define new inputs.** A common pattern:

```hcl
variable "name" { type = string }
variable "environment" { type = string }

locals {
  label = "${var.environment}-${var.name}"
  tags  = merge(var.extra_tags, { Name = local.label })
}
```

Resources use `local.label` and `local.tags`. Callers only set `var.name`, `var.environment`, and `var.extra_tags`.

### “Global” vs “specific to this configuration”

Terraform has **no global variables** across modules. Every module has its **own** `var.*` namespace.

What people mean in conversation:

- **Variables feel “global” at the root** because one `terraform.tfvars` or `TF_VAR_*` can affect many resources in that root module. Still, that is only the **root** module’s inputs.
- **Locals are “specific to this module’s configuration”** because they are not passed in from outside. Child module locals are invisible to the parent; root locals are invisible to children unless you pass them as **module arguments** (which means copying into a **child variable**, not referencing `local.x` across the boundary).

```text
Root                          Child module
------                        ------------
var.region  ──module arg──>   var.region
local.vpc_id (root only)      local.subnet_name (child only)
         \                    /
          both can be used inside their own module's resources
```

To share a root local with a child, you **explicitly** wire it: `cidr = local.vpc_cidr` on the `module` block → becomes `var.cidr` in the child. See [5b](../05-modules/05b-variable-scope).

## Locals vs outputs

| | **Local** | **Output** |
|---|---|---|
| Purpose | Reuse inside the module | Expose a value **out** to the caller or `terraform output` |
| Caller reads it? | No (`module.foo.local.x` does not exist) | Yes (`module.foo.name`) |

**Rule:** **`output` blocks are the only way out of a module.** The `value` of an output may be `local.something`, `resource.foo.id`, or `var.pass_through` — but the caller always reads **`module.<name>.<output>`**, never the child’s locals or resource addresses directly.

Put stable **API** results in **outputs**. Keep messy intermediates in **locals**. Module boundary detail: [5b](../05-modules/05b-variable-scope).

## When a module has “specific values”

A reusable module often fixes **conventions** in locals while exposing **choices** as variables:

```hcl
# Child module: opinionated layout, flexible inputs
variable "prefix" { type = string }

locals {
  filename = "${path.module}/files/${var.prefix}.txt"
}
```

The **caller** chooses `prefix`. The **module** owns how that becomes a path. That is locals doing “this module’s internal rules,” not variables duplicating the same string in every resource block.

## Exam traps

- **Required variable:** no `default` → caller **must** set it (root: tfvars / `TF_VAR_*` / `-var`; child: **`module` block argument**). Omitting it → **error**.
- **Optional variable:** use a **`default`** on the `variable` block (`default = ""` is valid). Do not use `type = optional(string)` on a standalone variable — `optional()` is only inside `object({ ... })`. See [4c](04c-variables-and-outputs) and [4d](04d-complex-types).
- **`local.filename` vs `var.filename`:** only `var` can be set from tfvars / `-var`. Locals are always computed in code.
- **Child cannot read parent `var`:** parent must pass `foo = var.foo` into `module { }`.
- **Backend and provider blocks** cannot use `var` or `locals` in many places (static configuration). That is a different rule; see [6c](../06-state/06c-remote-backend).
- **`terraform.workspace`** is not a variable; it is a built-in expression. You can assign it to a local: `locals { env = terraform.workspace }`.

## Examples in this repo

| Location | Pattern |
|---|---|
| [04c-variables-and-outputs/main.tf](04c-variables-and-outputs/main.tf) | `local.path` from `var.filename` |
| [04e-expressions-and-functions/main.tf](04e-expressions-and-functions/main.tf) | `locals` for `for`, `lookup`, `templatefile` |
| [04d-complex-types/main.tf](04d-complex-types/main.tf) | locals over maps and objects |
| [labs/local-stack/main.tf](../labs/local-stack/main.tf) | `local.label` from `var.name` and workspace |
| [cheatsheet.md](../cheatsheet.md) | syntax quick reference |
