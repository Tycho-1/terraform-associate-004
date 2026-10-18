# 2b — How Terraform uses providers

Docs: [How Terraform works with plugins](https://developer.hashicorp.com/terraform/plugin/how-terraform-works), [provider overview](https://developer.hashicorp.com/terraform/language/v1.12.x/providers).

Terraform core is the CLI: it loads configuration, builds the graph, stores state, and prints the plan. It has no built-in knowledge of AWS, Azure, or GitHub.

A provider is a **compiled binary** that core runs as a plugin process. Core does not build providers from source or embed provider code in the CLI. It starts the executable that `init` installed, and they talk over RPC. The provider reports the resource types it implements. Core asks the provider to plan and apply each resource. The provider calls the remote API.

```text
.tf files  ->  Terraform core  ->  provider plugin  ->  remote API
                     |
                     v
                   state
```

You will see this split in logs (`TF_LOG`). Lines about the graph and the state are core. Lines about an HTTP call to a cloud are the provider. See [7c](../../07-maintain/07c-logging).

## Use case: proprietary APIs on Azure

**Scenario.** Your team ships a new service that runs on Azure and exposes **proprietary HTTP APIs** (not Azure Resource Manager). You want Terraform to **create, update, and delete users** in that service the same way it manages `azurerm_*` resources: declarative configuration, plan/apply, and state that records each user's identity.

**Why the built-in `azurerm` provider is not enough.** `hashicorp/azurerm` implements Azure platform resources (resource groups, VMs, Key Vault, and so on). It does not know your company's user API. Terraform has no way to "add" those operations inside a normal `.tf` module without a plugin that speaks your API.

**What to do instead: develop and publish a custom provider.**

1. **Implement** a provider with the [Terraform Plugin Framework](https://developer.hashicorp.com/terraform/plugin/framework) (or the older SDK). You define resource types such as `myservice_user` with schema and CRUD handlers that call your proprietary API.
2. **Build** release binaries for each platform you support (`linux_amd64`, `darwin_arm64`, …). Terraform loads those executables; it does not compile your Go source at `init`. See [2a](../02a-provider-versions).
3. **Publish** the signed plugin to a registry your organization trusts. Proprietary services usually go to the **HCP Terraform private registry** or Terraform Enterprise, not the public `registry.terraform.io`. See [8b](../../08-hcp-terraform/08b-collaboration-governance).
4. **Consume** the provider from infrastructure code with an explicit `source` (not the default `hashicorp/` namespace):

```hcl
terraform {
  required_providers {
    myservice = {
      source  = "app.terraform.io/myorg/myservice" # private registry hostname + namespace
      version = "~> 1.0"
    }
  }
}

provider "myservice" {
  endpoint = "https://users.internal.example"
  # API key from env or HCP dynamic credentials pattern for your auth model
}

resource "myservice_user" "alice" {
  email = "alice@example.com"
  role  = "reader"
}
```

After `terraform init`, core runs your `myservice` plugin. Plan and apply drive create/update/delete against the proprietary API; state holds `myservice_user.alice` so the next plan can detect drift.

**Answers that miss the point on an exam:**

| Approach | Why it fails the use case |
|---|---|
| Use only `azurerm_*` resources | No mapping to your user API. Azure RM and your SaaS API are different surfaces. |
| Put provider Go code in the module and run `terraform init` | Core never builds providers from source. You ship binaries via a registry or mirror. |
| `local-exec` / `remote-exec` scripts to curl the API | Scripts are a last resort: weak lifecycle, poor drift handling, not modeled as resources in state. |
| A **module** alone (no new provider) | Modules compose existing resource types. They cannot invent a new `resource "foo_bar"` type without a plugin behind it. |

The exam associates this pattern with **custom providers** plus **private registry distribution**, not with extending HashiCorp's Azure provider or with provisioners as the primary design.

Docs: [Develop providers](https://developer.hashicorp.com/terraform/plugin), [Publish providers to a registry](https://developer.hashicorp.com/terraform/registry/providers/publishing).

## What the provider block is for

The `provider` block configures the plugin: region, endpoints, features. It does not declare that you need the plugin. `required_providers` does that.

```hcl
provider "random" {
  # The random provider has no required settings.
  # A cloud provider block is where region and credentials usually go.
}
```

Credentials can also come from the provider's normal environment variables (`AWS_ACCESS_KEY_ID`, `ARM_CLIENT_ID`, and so on). On HCP Terraform **remote** runs those env vars are set on the **workspace** (or via dynamic `TFC_*` OIDC), not taken from your laptop. See [provider-credentials.md](../../08-hcp-terraform/provider-credentials.md) and [8b](../../08-hcp-terraform/08b-collaboration-governance).

## How a resource finds its provider (inferred from the type name)

You do not set `provider =` on every resource. Terraform looks at the **resource type** string in the block header and takes the part **before the first underscore** as the provider local name.

```hcl
resource "aws_vpc" "shared" { }
#        ^^^^^^^^
#        type    -> provider "aws" (default configuration, no alias)

resource "azurerm_resource_group" "app" { }
#        ^^^^^^^^^^^^^^^^^^^^^^^
#        type    -> provider "azurerm"

resource "random_pet" "server" { }
#        ^^^^^^^^^^^
#        type    -> provider "random"
```

The second label in the header (`shared`, `app`, `server`) is only the **resource name inside your module**. It is not part of the provider lookup. `aws_vpc.shared` in an expression means the `shared` instance of type `aws_vpc`.

The same rule applies to `data` and `ephemeral` blocks:

```hcl
data "aws_ami" "ubuntu" { }
#     ^^^^^^^ -> provider "aws"

ephemeral "random_password" "db" { }
#          ^^^^^^^^^^^^^^^ -> provider "random"
```

That provider must exist in `required_providers` (with a `source` when it is not the default `hashicorp/<name>`). After `terraform init`, there must be a matching `provider "<name>"` block for configuration (region, credentials, features), unless the provider needs no settings and an empty default is enough.

`random_id.suffix` therefore talks to the `random` plugin. You only write `provider =` when you need a **non-default** configuration of the same provider, usually an **alias**. See [2c](../02c-multiple-providers).

| Type in the block | Provider Terraform selects |
|---|---|
| `aws_vpc` | default `provider "aws"` |
| `aws_instance` | default `provider "aws"` |
| `azurerm_kubernetes_cluster` | default `provider "azurerm"` |
| `google_compute_network` | default `provider "google"` |
| `local_file` | default `provider "local"` |

If the configuration has no `provider "random"` block, Terraform still infers `random` from `random_pet`, and assumes an empty default configuration. That is enough for providers with no required settings.

**Exam trap:** `provider = "aws"` as a string is wrong. When you override, use an expression: `provider = aws` or `provider = aws.dr`.

## What init leaves on disk

```text
.terraform/
  providers/
    registry.terraform.io/hashicorp/random/3.6.x/linux_amd64/
.terraform.lock.hcl
```

Delete `.terraform` and the working directory still has its configuration and state. The next `init` downloads the plugins again. Deleting `.terraform` does not destroy infrastructure.

## Exam distinctions

- Core decides order and stores state. The provider performs the API calls.
- Installing a provider is `terraform init`, not `terraform apply`. `init` fetches a pre-built plugin binary; Terraform does not compile provider source.
- A provider must be declared in `required_providers` when you care about source and version. Implicit `hashicorp/<name>` discovery still works for a resource prefix, and an explicit source is the practice you should recognize in a snippet.
- You can write configuration for a provider that is not installed yet. `validate` and `plan` need `init` first so the schema is available.
