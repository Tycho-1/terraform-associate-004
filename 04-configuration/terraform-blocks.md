# What is a “block” in Terraform?

Companion note for objectives **4a** (resources and data), **4e** (`dynamic` nested blocks), and **4g** (condition blocks). Docs: [Configuration syntax](https://developer.hashicorp.com/terraform/language/v1.12.x/syntax/configuration).

In Terraform HCL, a **block** is a named section of configuration written with **curly braces** `{ }`. It has a **type** (the first keyword) and usually one or two **labels** in quotes.

```hcl
resource "google_compute_instance" "web" {
  name = "web"                    # argument (name = value)

  network_interface {             # nested block
    network = "default"
  }
}
```

**`resource` is a block type.** **`data` is a block type.** They are siblings at the top level of a module, not “inside” each other.

## Top-level blocks (module building blocks)

These are the block kinds you declare in `.tf` files:

| Block type | Role |
|---|---|
| `resource` | Create, update, and destroy something Terraform manages |
| `data` | Read something that already exists (no destroy on remove) |
| `variable` | Module input |
| `output` | Module output |
| `locals` | Named expressions inside the module |
| `provider` | Configure a provider plugin (region, credentials, …) |
| `terraform` | Backend, `required_providers`, `required_version`, `cloud`, … |
| `module` | Call a child module |
| `import` | Adopt existing infrastructure into state ([7a](../07-maintain/07a-import)) |
| `moved` / `removed` | Refactor state without destroy ([6d](../06-state/06d-drift-and-refactor)) |
| `check` | Custom assertions that warn on failure ([4g](04g-custom-conditions)) |

When exam text says “add a **resource** block” or an **import** block, it means a whole section like `resource "type" "name" { … }` or `import { … }`.

## Nested blocks (inside a resource or data)

Inside a `resource` or `data` block, the **provider schema** often defines **nested blocks** for grouped or repeated settings. Examples:

- `network_interface { }` on a compute instance  
- `disk { }` / `data_disk { }` on a VM  
- `ingress { }` on a security group  
- `statement { }` inside `data "aws_iam_policy_document"`  

Those are still **blocks** (type name + `{ }`), not simple `key = value` arguments. The provider maps them to its API shape.

You can write several copies of a nested block by hand, or generate them from a variable with **`dynamic`**:

```hcl
dynamic "data_disk" {
  for_each = var.disks
  content {
    # one data_disk { } stanza per element
  }
}
```

See [4e](04e-expressions-and-functions).

## Block vs argument

| Form | Example | Meaning |
|---|---|---|
| **Argument** | `machine_type = "e2-medium"` | Single attribute assignment |
| **Nested block** | `network_interface { network = "default" }` | Structured sub-section; often repeatable |

Both appear **inside** a parent `resource`, `data`, `provider`, or similar block.

**Meta-arguments** on resources (`count`, `for_each`, `depends_on`, `provider`, `lifecycle`) look like arguments but are handled by Terraform core, not sent to the cloud API as-is. See [4a](04a-resources-and-data) and [lifecycle-block-reference.md](lifecycle-block-reference.md).

## Nested blocks vs separate resources

Sometimes networking is **nested** under one VM (`network_interface { }`). Sometimes the same cloud object is its **own** resource type (for example `google_compute_subnetwork` as a separate `resource` block). The provider documentation defines which pattern applies.

## Mental model

```text
module (.tf files)
├── resource "google_compute_instance" "web" {     ← top-level block
│     name = "web"                                 ← argument
│     network_interface { … }                      ← nested block
│   }
├── data "google_compute_network" "vpc" { … }      ← top-level block
├── variable "region" { … }                        ← top-level block
└── output "instance_name" { … }                   ← top-level block
```

## Related notes in this repo

| Topic | Where |
|---|---|
| `resource` vs `data` | [04a](04a-resources-and-data) |
| References (`resource.foo.bar`, `data.foo.bar`) | [04b](04b-references) |
| `variable`, `output`, `locals` | [04c](04c-variables-and-outputs), [locals-vs-variables.md](locals-vs-variables.md) |
| `dynamic` nested blocks | [04e](04e-expressions-and-functions) |
| `lifecycle { precondition { } }` | [lifecycle-block-reference.md](lifecycle-block-reference.md), [04g](04g-custom-conditions) |
