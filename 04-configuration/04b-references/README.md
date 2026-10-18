# 4b — References and cross-resource values

Docs: [References to named values](https://developer.hashicorp.com/terraform/language/v1.12.x/expressions/references), [resource addressing](https://developer.hashicorp.com/terraform/cli/v1.12.x/state/resource-addressing).

A reference reads a value and, when it points at a resource, creates a dependency. Terraform will not create `local_file.unit` until `random_pet.server` has an `id`.

```hcl
content = random_pet.server.id
```

You do not declare that edge yourself. The expression is the edge. `depends_on` is only for edges that have no expression. See [4f](../04f-dependencies-and-lifecycle).

## Anatomy of a managed resource reference

In configuration, a **managed resource** attribute is referenced **without** a `resource.` prefix:

```text
kubernetes_namespace.example.metadata[0].name
│                    │       │
│                    │       └── attribute (and nested indexes)
│                    └────────── local name (second label in the resource block)
└──────────────────────────── resource type (first label in the resource block)
```

```hcl
resource "kubernetes_namespace" "example" {
  metadata { name = "apps" }
}

resource "local_file" "unit" {
  content = kubernetes_namespace.example.metadata[0].name
}
```

The type string (`kubernetes_namespace`) already implies a **managed** resource. Terraform does not use a `resource.` prefix in expressions.

## `data.` is required; `resource.` is not valid

| Kind | Block in `.tf` | Reference in expressions |
|---|---|---|
| Managed resource | `resource "aws_instance" "web" { }` | `aws_instance.web.id` |
| Data source | `data "aws_ami" "ubuntu" { }` | `data.aws_ami.ubuntu.id` |

**Correct**

```hcl
aws_instance.web.private_ip
data.aws_ami.ubuntu.id
```

**Wrong on the exam**

```hcl
resource.aws_instance.web.id          # no resource. prefix exists
resource.kubernetes_namespace.example.name
data.aws_instance.web.id            # managed resources are not data sources; omit data.
```

Only **`data.`** gets a kind prefix (plus **`var.`**, **`local.`**, **`module.`**, **`ephemeral.`**, and **`terraform.`** for workspace/workspace metadata). Managed resources are the bare `type.name.attribute` form.

CLI **state addresses** (`terraform state show`, `-target`, `-replace`) use the same path **without** `data.` for resources and **with** the `data.` prefix for data sources: `data.aws_ami.ubuntu`, `aws_instance.web`.

## Address forms

| Value | Expression |
|---|---|
| Input variable | `var.filename` |
| Local value | `local.prefix` |
| Resource attribute | `random_pet.server.id` |
| Data source attribute | `data.local_file.unit.content` |
| Module output | `module.pet.name` |
| `count` instance | `random_pet.server[0].id` |
| `for_each` instance | `random_pet.server["web"].id` |
| Splat | `random_pet.server[*].id` |
| Ephemeral resource | `ephemeral.random_password.db.result` |
| This resource, inside `provisioner` or `postcondition` | `self.id` |

Resource addresses in the CLI (`terraform state show`, `-target`) use the same path without wrapping them in an expression: `random_pet.server["web"]`.

`module.pet` exposes outputs only. `module.pet.random_pet.this.id` is not valid. If the caller needs an attribute, the module declares an `output`.

## Indexes

Maps and objects use strings or identifiers.

```hcl
var.vpc_cidrs["us-east-1"]   # map, string key
var.vpc_cidrs.us-east-1      # invalid: the hyphen is not an identifier
var.object.name              # object attribute, identifier
var.names[0]                 # list or tuple, numeric index
```

The official sample uses `var.vpc_cidrs["us-east-1"]`. The options that drop `var.`, or that use `[0]` on a map, are wrong.

## Splat and `for` expressions

| Form | Result |
|---|---|
| `[for o in list : o.id]` | **list** |
| `{for o in list : o.key => o.value}` | **map** (`=>` required) |
| `resource.name[*].attribute` | **list** (splat over `count` / `for_each` instances) |

`random_pet.server[*].id` is a list of ids when `server` uses `count` or `for_each`. For `for_each`, splat walks values and the list order is not something to rely on for identity. A `for` expression is clearer when you need a map:

```hcl
{ for k, pet in random_pet.server : k => pet.id }
```

Full examples and `if` filters: [4e](../04e-expressions-and-functions).

## Strings and interpolation

```hcl
filename = "${path.module}/${var.filename}"
```

Inside `"..."`, `${ }` interpolates. A bare reference outside quotes is the value itself, with its real type. `"${var.ports}"` stringifies a list and is a smell. Pass `var.ports` through so the type stays a list.

`path.module` is the directory of the module file. `path.root` is the root module. `path.cwd` is the process working directory. In a child module those differ.

## Apply

```bash
cd 04-configuration/04b-references
terraform init && terraform apply
terraform state show local_file.unit
```

The file content is the pet id. That reference is why `local_file.unit` waits for `random_pet.server` in the graph.
