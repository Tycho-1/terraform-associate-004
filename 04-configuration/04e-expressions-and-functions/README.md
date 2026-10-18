# 4e — Expressions and functions

Docs: [Built-in functions](https://developer.hashicorp.com/terraform/language/v1.12.x/functions), [dynamic expressions](https://developer.hashicorp.com/terraform/tutorials/configuration-language/expressions), [functions tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/functions).

Expressions are how you compute a value from other values. Functions are the built-in operations you can call. There is no way to define your own function in Terraform 1.12. You wrap a repeated expression in a local, or you wrap a repeated resource pattern in a module.

To try a function or a `for` expression before you commit it to a file, run `terraform console` in a directory that has been `init`ed (and usually `apply`ed). See [07d-terraform-console](../../07-maintain/07d-terraform-console).

## The ones worth recognizing on sight

| Function | What it returns |
|---|---|
| `length(collection)` | number of elements, or characters in a string |
| `keys(map)` / `values(map)` | lists of keys or values |
| `lookup(map, key, default)` | the value, or the default if the key is absent |
| `merge(map1, map2)` | one map; later maps win on duplicate keys |
| `flatten(list)` | one list, with nested lists spliced in |
| `distinct(list)` | list with duplicates removed, order kept |
| `compact(list)` | list with empty strings removed |
| `concat(list1, list2)` | the lists joined |
| `toset` / `tolist` / `tomap` | conversions |
| `contains(list, value)` | bool |
| `coalesce(a, b)` | the first value that is not null or empty string |
| `try(expr, fallback)` | fallback when expr fails |
| `can(expr)` | true when expr would succeed |
| `templatefile(path, vars)` | a file with `${name}` replaced from a map |
| `file(path)` | the file as a string |
| `jsonencode` / `jsondecode` | JSON |
| `yamlencode` / `yamldecode` | YAML |
| `cidrsubnet(prefix, newbits, netnum)` | a subnet CIDR |
| `upper` / `lower` / `replace` / `format` | strings |
| `sensitive(value)` | the same value, marked sensitive |
| `nonsensitive(value)` | strips the sensitive mark; the value can then leak into output |

`templatefile` reads a file relative to the current working directory, not `path.module`, unless you write `"${path.module}/unit.tftpl"`.

`try` and `can` swallow errors, including typos. Use them when a value may legitimately be missing, not to hide a broken reference.

## for expressions

```hcl
locals {
  upper_names = [for name in var.names : upper(name)]

  long_names = [for name in var.names : upper(name) if length(name) > 2]

  cidr_by_region = {
    for region, cidr in var.regions : upper(region) => cidr
  }
}
```

The **brackets** decide the result type. **`[...]` → list** (or tuple). **`{ ... => ... }` → map** (or object). `if` filters elements. In a map comprehension, `=>` separates each key from its value.

| Expression | Output type |
|---|---|
| `[for o in var.list : o.id]` | **List** of `id` values |
| `{for o in var.list : o.key => o.value}` | **Map** from each element's `key` to `value` |
| `{for region, cidr in var.regions : region => cidr}` | **Map** (walk a map or set of objects) |

```hcl
locals {
  ids = [for o in var.objects : o.id]

  by_key = { for o in var.objects : o.key => o.value }

  upper_regions = { for region, cidr in var.regions : upper(region) => cidr }
}
```

**Splat** (attribute-only shorthand when the resource uses `count` or `for_each`):

| Expression | Output type |
|---|---|
| `random_pet.server[*].id` | **List** of every instance's `id` |

Splat is not a `for` expression; it is index syntax with `[*]`. Same idea as collecting one attribute from many instances. For a **map** keyed by instance, prefer `{ for k, pet in random_pet.server : k => pet.id }` instead of relying on splat list order. More detail: [4b](../04b-references).

## Conditional

```hcl
local.primary_cidr = var.enable_public ? var.regions["eu-central-1"] : "0.0.0.0/0"
```

Both branches must be the same type. `condition ? "yes" : 1` is a type error. There is no `if` statement. Terraform is an expression language.

## dynamic blocks

A `dynamic` block repeats a **nested** block inside a `resource`, `data`, or `provider` block. **`dynamic` always uses `for_each`** (not `count`) to walk a collection. That is the same `for_each` idea as on a resource, but here it generates **nested** block bodies instead of whole resources.

| Part | Purpose |
|---|---|
| `dynamic "<block_name>"` | Which **nested block type** to repeat (must match the provider schema, e.g. `"data_disk"`, `"ingress"`) |
| `for_each` | The **collection** to iterate (list, set, or map — often a variable) |
| `content { }` | The **body** of each generated nested block |
| `<block_name>.value` | Current element (for a list/set, the value; for a map, the value) |
| `<block_name>.key` | Current index (list position) or map key |

The iterator name defaults to `<block_name>`. You can rename it with `iterator = alias` and then use `alias.value` / `alias.key` inside `content`.

```hcl
dynamic "line" {
  for_each = var.names
  content {
    text = line.value
  }
}
```

Inside `content`, `line.key` and `line.value` are the pair. An empty `for_each` collection produces **zero** nested blocks.

**Exam line:** `dynamic` is the only way to **programmatically** generate **repeated nested blocks** inside one resource from a variable or collection. Use resource-level `count` / `for_each` when you need multiple resources, not multiple nested stanzas inside one resource.

You cannot dynamic-generate top-level `resource` blocks. Repeating resources is `count` or `for_each` on the resource itself. Repeating nested blocks (`ingress`, `tag`, `statement`, `data_disk`) is `dynamic`.

### Use case: multiple nested blocks from a variable

**Scenario.** You want several **data disks** (or `ingress` rules, `tag` blocks, and so on) defined as **nested blocks inside one virtual machine resource**, with the disk list coming from a **variable**.

**Answer: `dynamic` blocks.** Put `for_each` on `dynamic "<nested_block_type>"` and map each element of the variable into `content { ... }`.

```hcl
variable "data_disks" {
  type = list(object({
    name                 = string
    lun                  = number
    disk_size_gb         = number
    storage_account_type = string
  }))
  default = []
}

resource "azurerm_linux_virtual_machine" "example" {
  # ... vm arguments omitted ...

  dynamic "data_disk" {
    for_each = var.data_disks
    content {
      name                 = data_disk.value.name
      lun                  = data_disk.value.lun
      disk_size_gb         = data_disk.value.disk_size_gb
      storage_account_type = data_disk.value.storage_account_type
    }
  }
}
```

The block label `"data_disk"` must match the nested block type the provider schema expects. The iterator name defaults to `data_disk`, so inside `content` you use `data_disk.value` (and `data_disk.key` for the index in a list).

**Why the other features are wrong:**

| Feature | Why it does not fit |
|---|---|
| `count` / `for_each` on the **resource** | Creates **multiple VM resources**, not multiple `data_disk` blocks inside **one** VM. |
| `for` expression in `locals` | Builds a **list or map value**; it does not emit nested HCL blocks in the provider API shape. |
| `dynamic` on a top-level `resource` | Invalid syntax. `dynamic` only wraps **nested** blocks. |

Docs: [dynamic blocks](https://developer.hashicorp.com/terraform/language/v1.12.x/expressions/dynamic-blocks).

## count versus for_each, again

```hcl
resource "random_pet" "counted" {
  count  = length(var.names)
  length = 1
  prefix = var.names[count.index]
}

resource "random_pet" "named" {
  for_each = toset(var.names)
  length   = 1
  prefix   = each.value
}
```

`random_pet.counted[0]` changes meaning if you reorder `var.names`. `random_pet.named["web"]` does not.

## Apply

```bash
cd 04-configuration/04e-expressions-and-functions
terraform init && terraform apply
cat rendered.txt
```

`rendered.txt` is the template plus the `for` expression output. Compare it with `locals` in `main.tf` if a function's result surprises you.

## Extra notes in this folder

- [local-file-unit-explained.md](local-file-unit-explained.md) — walkthrough of `local_file.unit` and `path.module`
- [local-provider-and-provisioners.md](local-provider-and-provisioners.md) — `local` provider vs `local-exec` / `remote-exec` vs `terraform_data`
