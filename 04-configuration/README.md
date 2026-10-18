# 4 — Terraform configuration

Language and structure: resources, inputs, expressions, lifecycle, and conditions. **4f, 4g, and the ephemeral / write-only part of 4h are new in 004.** Index: [new-in-004.md](../00-before-the-exam/new-in-004.md).

## `count` vs `for_each`

Both meta-arguments create **multiple instances** of the same resource or module block. They are not interchangeable: **state addresses** and **what happens when the input collection changes** differ.

| | `count` | `for_each` |
|---|---|---|
| **Argument** | A number, or `length(list)` | A **map** or a **set of strings** (often `toset(var.names)`) |
| **Inside the block** | `count.index` | `each.key`, `each.value` |
| **State address** | `random_pet.server[0]`, `random_pet.server[1]` | `random_pet.server["web"]`, `random_pet.server["api"]` |
| **Identity** | The **index** is the identity | The **key** is the identity |

**Prefer `for_each` when each instance has a stable name** (hostname, environment, role). If you insert an element at the front of a list used with `count`, indices shift and Terraform may plan **destroy/create** for objects that only moved. With `for_each`, the key `"web"` still refers to the same instance after reordering.

```hcl
resource "random_pet" "by_count" {
  count  = length(var.names)
  prefix = var.names[count.index]
}

resource "random_pet" "by_name" {
  for_each = toset(var.names)
  prefix   = each.value
}
```

References: `random_pet.by_count[0].id` vs `random_pet.by_name["web"].id`. The same rules apply on **`module`** blocks. You cannot use `count` and `for_each` on the **same** block.

**Related but different:** a `for` **expression** in `locals` only computes a value. A **`dynamic` block** repeats a **nested** block inside one resource. See [04e](04e-expressions-and-functions), [04d](04d-complex-types), [05c](../05-modules/05c-use-modules), and the [cheatsheet](../cheatsheet.md).

| Note | Objective |
|---|---|
| [04a-resources-and-data](04a-resources-and-data) | `resource` vs `data`; what data sources can fetch |
| [terraform-blocks.md](terraform-blocks.md) | What a “block” is (resource, data, nested, vs arguments) |
| [04b-references](04b-references) | Addresses and cross-references |
| [04c-variables-and-outputs](04c-variables-and-outputs) | Inputs and outputs |
| [locals-vs-variables.md](locals-vs-variables.md) | When to use `variable` vs `locals` (companion to 4c / 5b) |
| [04d-complex-types](04d-complex-types) | list, set, map, object, tuple |
| [04e-expressions-and-functions](04e-expressions-and-functions) | `for`, `dynamic`, functions |
| [04f-dependencies-and-lifecycle](04f-dependencies-and-lifecycle) | **New in 004.** `depends_on`, `create_before_destroy` |
| [lifecycle-block-reference.md](lifecycle-block-reference.md) | All `lifecycle` arguments (companion to 4f / 4g) |
| [04g-custom-conditions](04g-custom-conditions) | **New in 004.** validation, pre/postconditions, checks |
| [04h-sensitive-data](04h-sensitive-data) | **New in 004:** ephemeral values, write-only arguments. Also sensitive data and Vault |

Each folder has HCL you can `init` and `apply`, except the AWS write-only sketch in 4h, which is an `.example` file.
