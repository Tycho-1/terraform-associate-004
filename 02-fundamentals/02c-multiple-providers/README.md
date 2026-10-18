# 2c — Multiple providers

Docs: [Provider configuration](https://developer.hashicorp.com/terraform/language/v1.12.x/providers/configuration).

Two different needs look similar in questions.

**Several provider types in one configuration.** `random` and `local` together, or `aws` and `azurerm` together. Each type name implies its provider (`aws_vpc` → `aws`, `azurerm_resource_group` → `azurerm`). One state file tracks all of them. This is the multi-cloud case from [1c](../../01-infrastructure-as-code/01c-multi-cloud). The inference rule is spelled out in [2b](../02b-how-providers-work).

**Several configurations of one provider.** Two AWS regions, two Azure subscriptions, two Kubernetes clusters. The second configuration has an `alias`. Resources use the default unless they set `provider =`.

```hcl
provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "dr"
  region = "eu-west-1"
}

resource "aws_instance" "primary" {
  # uses provider "aws" with no alias
}

resource "aws_instance" "backup" {
  provider = aws.dr
}
```

The alias is `dr`. The expression that selects it is `aws.dr` with a dot, no quotes.

## Passing providers into a module

Child modules do not inherit aliases. You pass them:

```hcl
module "backup" {
  source = "./modules/instance"

  providers = {
    aws = aws.dr
  }
}
```

Inside the module, that configuration is the module's default `aws` provider. The module's resources do not write `provider = aws.dr`; the caller decided.

## This folder

`random` has no region, so the alias here is only a label. The pattern is the same one you use for two AWS regions. `local_file` is a second provider type in the same state.

```bash
cd 02-fundamentals/02c-multiple-providers
terraform init
terraform apply
terraform state list
```

`terraform state list` shows both `random_pet.primary` and `random_pet.backup`. One state, two provider configurations.

## Exam traps

- A second `provider` block without `alias` is a duplicate default configuration and Terraform rejects it.
- `provider = "aws.dr"` as a string is wrong. It is an expression: `provider = aws.dr`.
- The `provider` meta-argument on a resource picks the configuration. It does not install the plugin.
- `required_providers` lists each provider type once, not once per alias.
