# 5a — How Terraform sources modules

Docs: [Module sources](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/sources), [find and use modules](https://developer.hashicorp.com/terraform/registry/modules/use), [modules overview](https://developer.hashicorp.com/terraform/tutorials/modules/module).

The `source` argument of a `module` block tells Terraform where the child module's files are. `terraform init` downloads it into `.terraform/modules`.

| Source | Example |
|---|---|
| Local path | `./modules/pet` or `../pet` |
| Terraform Registry | `terraform-aws-modules/vpc/aws` |
| Git | `git::https://example.com/network.git//modules/vpc?ref=v1.2.0` |
| GitHub shorthand | `github.com/org/repo` |
| Generic Mercurial, S3, GCS, HTTP | a URL with the matching scheme |

A local path is relative to the file that contains the `module` block. It is re-read from disk on each plan. Changing a local module does not require a fresh download. `terraform init` is still required the first time, and again when you add a new module block.

A registry address has three parts: `namespace/name/provider`, for example `terraform-aws-modules/vpc/aws`. The provider segment is the provider the module was written for, and it is part of the address, not a separate argument.

Git sources are downloaded at init. `?ref=` selects a tag, branch, or commit. After you change `ref`, run `terraform init` again. `init -upgrade` also checks modules for newer matching versions.

## The Registry

The public Terraform Registry is `registry.terraform.io`. A module page shows inputs, outputs, and the source string you copy. HCP Terraform adds a private registry for modules and providers that stay inside an organization. The source hostname becomes the HCP Terraform registry host. See [8b](../../08-hcp-terraform/08b-collaboration-governance).

You can publish a module to the public registry when the repository follows the standard layout: Terraform configuration at the root, `README.md`, `LICENSE`, and a version tag. The exam does not ask you to publish one. It asks you to recognize a registry source and a local source.

## What init does with a module

- Local: records the module in `.terraform/modules/modules.json`
- Remote: copies the selected version into `.terraform/modules/<key>`

Deleting `.terraform` only deletes the download. The next init fetches it again. It does not destroy the infrastructure the module created. That infrastructure is in state, under addresses that start with `module.<name>`.
