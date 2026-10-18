# Exam objectives — Terraform Associate 004

Source: [Exam content list](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004) and the [certification page](https://developer.hashicorp.com/certifications/terraform-associate). The published wording, plus every documentation and tutorial link from that page, is in [exam-curriculum.md](exam-curriculum.md).

HashiCorp does not publish a percentage weight. The only size signal is the number of sub-objectives. Objective 4 has eight. Objective 3 has seven. Study all of them.

**New in 004**, compared with exam 003: Terraform 1.12, HCP Terraform (objective 8), and four topics — 4f, 4g, 4h (ephemeral values and write-only arguments), and 8c. Those notes are indexed in [new-in-004.md](new-in-004.md).

Docs below are the Terraform 1.12 pages the content list points at. A tutorial that uses AWS still teaches a provider-neutral idea.

## 1 — Infrastructure as Code (IaC) with Terraform

- [1a Explain what IaC is](../01-infrastructure-as-code/01a-what-is-iac) — [What is Terraform?](https://developer.hashicorp.com/terraform/intro/v1.12.x)
- [1b Describe the advantages of IaC patterns](../01-infrastructure-as-code/01b-advantages) — [Why Terraform](https://developer.hashicorp.com/terraform/intro#why-terraform)
- [1c Multi-cloud, hybrid cloud, and service-agnostic workflows](../01-infrastructure-as-code/01c-multi-cloud) — [Use cases](https://developer.hashicorp.com/terraform/intro/v1.12.x/use-cases)

Broader IaC comparisons (not on the exam): [terraform-vs-iac](../terraform-vs-iac/README.md).

## 2 — Terraform fundamentals

- [2a Install and version providers](../02-fundamentals/02a-provider-versions) — [Provider requirements](https://developer.hashicorp.com/terraform/language/v1.12.x/providers/requirements), [lock file](https://developer.hashicorp.com/terraform/language/v1.12.x/files/dependency-lock)
- [2b How Terraform uses providers](../02-fundamentals/02b-how-providers-work) — [How Terraform works with plugins](https://developer.hashicorp.com/terraform/plugin/how-terraform-works)
- [2c Multiple providers](../02-fundamentals/02c-multiple-providers) — [Provider block](https://developer.hashicorp.com/terraform/language/v1.12.x/providers/configuration)
- [2d How Terraform uses state](../02-fundamentals/02d-state) — [Purpose of state](https://developer.hashicorp.com/terraform/language/v1.12.x/state/purpose)

## 3 — Core Terraform workflow

- [3a The workflow](../03-core-workflow/03a-workflow) — [Core workflow](https://developer.hashicorp.com/terraform/intro/v1.12.x/core-workflow)
- [3b Initialize a working directory](../03-core-workflow/03b-init) — [terraform init](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/init)
- [3c Validate configuration](../03-core-workflow/03c-validate) — [terraform validate](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/validate)
- [3d Generate and review a plan](../03-core-workflow/03d-plan) — [terraform plan](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/plan), [resource graph](https://developer.hashicorp.com/terraform/internals/v1.12.x/graph)
- [3e Apply changes](../03-core-workflow/03e-apply) — [terraform apply](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/apply)
- [3f Destroy managed infrastructure](../03-core-workflow/03f-destroy) — [terraform destroy](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/destroy)
- [3g Format and style](../03-core-workflow/03g-fmt) — [terraform fmt](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/fmt)

## 4 — Terraform configuration

- [4a Resource and data blocks](../04-configuration/04a-resources-and-data) — [Resources](https://developer.hashicorp.com/terraform/language/v1.12.x/resources), [data sources](https://developer.hashicorp.com/terraform/language/v1.12.x/data-sources)
- [4b References and cross-resource values](../04-configuration/04b-references) — [References](https://developer.hashicorp.com/terraform/language/v1.12.x/expressions/references), [addresses](https://developer.hashicorp.com/terraform/cli/v1.12.x/state/resource-addressing)
- [4c Variables and outputs](../04-configuration/04c-variables-and-outputs) — [Variable block](https://developer.hashicorp.com/terraform/language/v1.12.x/block/variable), [output block](https://developer.hashicorp.com/terraform/language/v1.12.x/block/output)
- [4d Complex types](../04-configuration/04d-complex-types) — [Type constraints](https://developer.hashicorp.com/terraform/language/v1.12.x/expressions/type-constraints)
- [4e Expressions and functions](../04-configuration/04e-expressions-and-functions) — [Functions](https://developer.hashicorp.com/terraform/language/v1.12.x/functions), [expressions tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/expressions)
- [4f Dependencies and lifecycle](../04-configuration/04f-dependencies-and-lifecycle) — **New in 004.** [depends_on](https://developer.hashicorp.com/terraform/language/v1.12.x/meta-arguments/depends_on), [lifecycle](https://developer.hashicorp.com/terraform/language/v1.12.x/meta-arguments/lifecycle)
- [4g Custom conditions](../04-configuration/04g-custom-conditions) — **New in 004.** [Validate your configuration](https://developer.hashicorp.com/terraform/language/v1.12.x/validate)
- [4h Sensitive data, ephemeral values, write-only arguments, Vault](../04-configuration/04h-sensitive-data) — **New in 004:** ephemeral values and write-only arguments. [Manage sensitive data](https://developer.hashicorp.com/terraform/language/v1.12.x/manage-sensitive-data)

## 5 — Terraform modules

- [5a How Terraform sources modules](../05-modules/05a-module-sources) — [Module sources](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/sources)
- [5b Variable scope inside modules](../05-modules/05b-variable-scope) — [Module inputs](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/develop/composition)
- [5c Use modules in configuration](../05-modules/05c-use-modules) — [Use modules](https://developer.hashicorp.com/terraform/language/v1.12.x/modules/develop)
- [5d Manage module versions](../05-modules/05d-module-versions) — [version argument](https://developer.hashicorp.com/terraform/language/v1.12.x/block/module#version)

## 6 — Terraform state management

- [6a The local backend](../06-state/06a-local-backend) — [local backend](https://developer.hashicorp.com/terraform/language/v1.12.x/backend/local)
- [6b State locking](../06-state/06b-locking) — [State locking](https://developer.hashicorp.com/terraform/language/v1.12.x/state/locking)
- [6c Remote state with the backend block](../06-state/06c-remote-backend) — [Backend configuration](https://developer.hashicorp.com/terraform/language/v1.12.x/backend)
- [6d Drift and state refactoring](../06-state/06d-drift-and-refactor) — [Drift tutorial](https://developer.hashicorp.com/terraform/tutorials/state/resource-drift), [moved](https://developer.hashicorp.com/terraform/language/v1.12.x/block/moved), [removed](https://developer.hashicorp.com/terraform/language/v1.12.x/block/removed)

## 7 — Maintain infrastructure with Terraform

- [7a Import existing infrastructure](../07-maintain/07a-import) — [Import](https://developer.hashicorp.com/terraform/cli/v1.12.x/import)
- [7b Inspect state with the CLI](../07-maintain/07b-inspect-state) — [terraform state](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/state)
- [7c Verbose logging](../07-maintain/07c-logging) — [Debugging](https://developer.hashicorp.com/terraform/internals/v1.12.x/debugging)
- [7d `terraform console`](../07-maintain/07d-terraform-console) — [Command: console](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/console) (supplementary; not on the published objective list)
- [7e `terraform test`](../07-maintain/07e-terraform-test) — [Tests](https://developer.hashicorp.com/terraform/language/tests), [Command: test](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/test) (supplementary; not on the published objective list)

## 8 — HCP Terraform

**New in 004.** Exam 003 did not include this objective.

- [8a Create infrastructure with HCP Terraform](../08-hcp-terraform/08a-create-infrastructure) — [Overview](https://developer.hashicorp.com/terraform/cloud-docs), [remote operations](https://developer.hashicorp.com/terraform/cloud-docs/run/remote-operations)
- [8b Collaboration and governance](../08-hcp-terraform/08b-collaboration-governance) — [Teams](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/teams), [policy](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement), [health](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health)
- [8c Workspaces and projects](../08-hcp-terraform/08c-workspaces-and-projects) — **New topic inside objective 8.** [Projects](https://developer.hashicorp.com/terraform/cloud-docs/projects), [run triggers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-triggers)
- [8d CLI integration](../08-hcp-terraform/08d-cli-integration) — [cloud block](https://developer.hashicorp.com/terraform/cli/cloud/settings), [terraform login](https://developer.hashicorp.com/terraform/cli/commands/login)
