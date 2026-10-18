# 4d — Complex types

Docs: [Type constraints](https://developer.hashicorp.com/terraform/language/v1.12.x/expressions/type-constraints).

Terraform's type system shows up whenever a question asks how to index a variable. Learn the five complex types by how you read an element.

## Primitive types

`string`, `number`, `bool`. Numbers are not split into int and float in the language. `true` and `false` are bools, not strings. `"true"` is a string.

## Collection types: one element type

| Type | Order | Index | Duplicates |
|---|---|---|---|
| `list(string)` | yes | number | allowed |
| `set(string)` | no | you convert it first | unique |
| `map(string)` | no | string key | keys are unique |

```hcl
variable "names" {
  type    = list(string)
  default = ["web", "api"]
}

variable "regions" {
  type = map(string)
  default = {
    eu-central-1 = "10.0.0.0/16"
    eu-west-1    = "10.1.0.0/16"
  }
}
```

`var.names[0]` is `"web"`. `var.regions["eu-central-1"]` is the CIDR. `var.regions[0]` is a type error because a map is not a list.

A set has no index. `toset(["a", "a", "b"])` has two elements. To walk a set, use `for_each` or convert with `tolist`.

## Structural types: a schema

| Type | Shape |
|---|---|
| `tuple([string, number])` | fixed positions, each position has its own type |
| `object({ name = string, port = number })` | named attributes, each has its own type |

```hcl
variable "service" {
  type = object({
    name = string
    port = number
    tags = optional(map(string), {})
  })
}
```

`var.service.name` and `var.service.port` are the reads. `optional` means the attribute may be omitted, and the second argument is the default when it is omitted.

### `optional()` only inside `object` types

`optional(string)` and `optional(number, 8080)` are **type modifiers for object attributes**. They belong in the `type = object({ ... })` of a variable (or in similar type constraints). They are **not** valid as the entire type of a variable:

```hcl
type = optional(string)              # invalid
type = list(optional(string))        # invalid in standard variable constraints
type = object({ tag = optional(string, "") })   # valid
```

If the exam asks how to make a **single** `string` variable optional for callers, the answer is **`default = ""`** or another `default` on the `variable` block, not `optional(string)`. See [4c](../04c-variables-and-outputs).

`list` is "zero or more of the same type." `tuple` is "exactly these positions, these types." `map` is "string keys, one value type." `object` is "these attribute names, these types."

## The `any` constraint

`type = any` accepts whatever value you pass and Terraform picks a concrete type from it. It is convenient and weak. Prefer an explicit type on variables that other people set. `any` still appears in older examples, including the official sample, which declares `type = map` with no element type. Modern style writes `map(string)`.

## Conversion

Terraform converts some values automatically: a list can satisfy a tuple of the same types, a single string sometimes becomes a list of one when the argument type is a list. Do not lean on that in your own modules. `tolist`, `toset`, `tomap`, `tostring`, and `tonumber` make the conversion obvious.

`null` is the absence of a value. An omitted optional argument and an argument set to `null` both mean "not set" for most provider arguments.

## for_each wants a map or a set of strings

```hcl
resource "local_file" "unit" {
  for_each = var.regions

  filename = "${path.module}/${each.key}.txt"
  content  = each.value
}
```

`each.key` and `each.value` exist only inside that block. With a map, the key is the region and the value is the CIDR. With `toset(var.names)`, the key and the value are the same string.

`count` gives you `count.index`. Prefer `for_each` when instances have a stable identity. Inserting a name at the front of a `count` list shifts every index, and Terraform plans replacements for objects that only moved position.

## Apply

```bash
cd 04-configuration/04d-complex-types
terraform init && terraform apply
terraform state list
```

You get one file per map key: `local_file.unit["eu-central-1"]` and `local_file.unit["eu-west-1"]`.
