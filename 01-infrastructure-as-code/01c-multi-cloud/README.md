# 1c — Multi-cloud, hybrid cloud, service-agnostic

Docs: [Multi-cloud deployment](https://developer.hashicorp.com/terraform/intro/v1.12.x/use-cases#multi-cloud-deployment).

Terraform core is the same binary everywhere. Providers are the part that changes. One configuration can declare an AWS network, an Azure resource group, and a Google Cloud address, and one state file tracks all of them. The workflow (`init`, `plan`, `apply`) does not change when the provider changes.

That is the sense in which Terraform is multi-cloud and service-agnostic. The resource types themselves are not portable. `aws_instance` means nothing to the Azure provider. There is no generic `compute_instance` in Terraform core.

## Three phrases the exam uses

**Multi-cloud.** More than one public cloud in the same configuration or the same operating model. Teams do this to use a service that is stronger in one cloud, or to keep an option open. Terraform gives them one workflow and one state model. It does not translate an AWS resource into an Azure resource.

**Hybrid cloud.** Some infrastructure in a public cloud and some in a private datacenter (VMware, OpenStack, bare metal through a provider, plus a cloud provider). Same idea: one configuration, several providers, one state.

**Service-agnostic.** The workflow manages SaaS and platforms as well as virtual machines: GitHub repositories, Kubernetes objects, Datadog monitors, Cloudflare records, Vault policies. If a provider exists, it is the same graph, plan, and state.

## What you actually write

`multi-cloud.tf.example` in this folder is a readable sketch of two cloud providers in one configuration. The `.example` suffix keeps Terraform from loading it. The runnable version of "several providers, one state" is [02c](../../02-fundamentals/02c-multiple-providers), using `random` and `local`.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
```

Each `resource` type selects its provider by the prefix before the first underscore. `aws_vpc.shared` uses the `aws` provider. `azurerm_resource_group.app` uses `azurerm`. One `terraform apply` walks both.

## A distinction that shows up in answers

Writing configuration that targets several clouds is normal.

Expecting the same `.tf` file to create identical infrastructure on any cloud, with no provider-specific blocks, is not how Terraform works. Portability is at the workflow and module-composition layer. A well-factored module can hide provider differences behind inputs and outputs, and the caller still picks a provider inside the module.

State is unified. Destroying the configuration destroys every managed resource in that state, in every cloud, in dependency order. That is a reason to split state by lifecycle (network in one workspace, application in another) when the blast radius matters. See [8c](../../08-hcp-terraform/08c-workspaces-and-projects).
