# 5c — Use modules in configuration

Docs: [Use modules](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/develop), [standard module structure](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/develop/structure), [build a local module](https://developer.hashicorp.com/terraform/tutorials/modules/module-create), [Google Cloud style and structure](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure).

A module call looks like a resource with a `source`.

```hcl
module "pet" {
  source = "./modules/pet"

  prefix = "web"
  length = 2
}

output "pet_name" {
  value = module.pet.name
}
```

The local name `pet` becomes part of every address: `module.pet.random_pet.this` in state, `module.pet.name` for the output.

## Standard files inside a module

HashiCorp's conventional layout, which the registry also expects:

```text
modules/pet/
  main.tf          # resources
  variables.tf     # inputs
  outputs.tf       # outputs
  versions.tf      # required_providers, so the module is explicit about plugins
  README.md
```

Terraform does not require those filenames. It loads every `.tf` file in the directory. The split is for people. A minimal module can be one file. A published module should have the standard split, a license, and examples.

Google's [style and structure guide](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure) is the practical version of that layout: `variables.tf` and `outputs.tf`, a `README.md`, examples under `examples/`, static files under `files/`, templates as `templates/*.tftpl`, resource names in `snake_case` (singular, and `main` when there is only one of that type), and outputs that reference resource attributes so the dependency graph stays intact.

## Composition

Call several modules from the root and pass outputs across:

```hcl
module "network" {
  source = "./modules/network"
}

module "app" {
  source  = "./modules/app"
  subnet_id = module.network.subnet_id
}
```

That reference is an implicit dependency between modules. The app module waits for the network module.

Prefer small modules with a single purpose (a pet name, a VPC, a database) composed at the root, over one module that creates an entire company. The exam phrase for this is module composition: the root module wires children together, children do not reach into each other.

## Count and for_each on a module

```hcl
module "pet" {
  source   = "./modules/pet"
  for_each = toset(["web", "api"])
  prefix   = each.key
}
```

Addresses become `module.pet["web"].name`. The same index rules as resources apply. Reordering a `count` on a module renumbers instances and plans replacements.

## Apply

```bash
cd 05-modules/05c-use-modules
terraform init
terraform apply
terraform state list
terraform output pet_name
```

`terraform state list` shows `module.pet.random_pet.this` and `module.pet.local_file.unit`. The root module's output reads only `module.pet.name`.
