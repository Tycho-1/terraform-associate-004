# Terraform study and reference

[![Terraform](https://img.shields.io/badge/Terraform-1.12-844FBA?logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![HCP Terraform](https://img.shields.io/badge/HCP%20Terraform-docs-000000?logo=hashicorp&logoColor=white)](https://developer.hashicorp.com/hcp/docs/terraform)
[![Curriculum](https://img.shields.io/badge/Curriculum-Associate%20004-5C4EE5)](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform CI](https://github.com/Tycho-1/terraform-associate-004/actions/workflows/terraform.yml/badge.svg)](https://github.com/Tycho-1/terraform-associate-004/actions/workflows/terraform.yml)

Notes, runnable examples, and companion docs for learning **Terraform** (open-source CLI, HCL, state, modules) and **HCP Terraform**. The tree is organized around the [Terraform Associate (004) exam content list](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004) — not because this repo is only for candidates, but because that curriculum is a solid map of **what matters**: which commands, language features, and platform behaviors are worth understanding deeply.

Use it as a **study guide** while you prepare, and as a **reference** afterward when you need the precise rule (backend vs `cloud`, when a `check` warns vs errors, how remote state differs from remote execution, and so on).

**Beyond the exam:** [terraform-vs-iac](terraform-vs-iac/README.md) compares Terraform to other IaC and platform tools (Kubernetes/GitOps, Ansible, Crossplane, Atlantis vs HCP) — same problems, different engines; not exam objectives, but useful for platform design after the curriculum clicks.

Official certification details (format, fees, registration): HashiCorp [certification page](https://developer.hashicorp.com/certifications/terraform-associate).

## Start here

| Resource | Role |
|---|---|
| [cheatsheet.md](cheatsheet.md) | Commands, syntax, and exam-style one-liners |
| [00-before-the-exam](00-before-the-exam) | Exam prep: orientation, [curriculum](00-before-the-exam/exam-curriculum.md), [objectives](00-before-the-exam/exam-objectives.md), [new in 004](00-before-the-exam/new-in-004.md) |
| [labs/local-stack](labs/local-stack) | One stack you can `apply` without a cloud account |
| [practice](practice) | Original practice questions (not from the live exam) |
| [terraform-vs-iac](terraform-vs-iac/README.md) | **Terraform vs other IaC** — Ansible, K8s/GitOps, Crossplane ([examples](terraform-vs-iac/crossplane/examples/README.md)), Atlantis; not on the exam |
| [reference-platforms.md](reference-platforms.md) | Linked EKS/GKE/AKS Terraform platform repos |
| [locals vs variables](04-configuration/locals-vs-variables.md) | When to use `locals` instead of `variable` |

**Also useful:** [declarative Terraform and Kubernetes](terraform-vs-iac/declarative-terraform-and-kubernetes.md), [Crossplane series](terraform-vs-iac/crossplane/README.md).

Style after the exam (not tested on Associate): [Google Cloud Terraform style guide](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure).

## How this folder is organized

One directory per curriculum objective: what the topic is about, the HCL you would write, and (where it fits) commands to try it yourself.

| Folder | Focus |
|---|---|
| [00-before-the-exam](00-before-the-exam) | Exam prep: orientation, [curriculum](00-before-the-exam/exam-curriculum.md), [objectives](00-before-the-exam/exam-objectives.md), [new in 004](00-before-the-exam/new-in-004.md) |
| [01-infrastructure-as-code](01-infrastructure-as-code) | IaC concepts, multi-cloud (exam objectives) |
| [terraform-vs-iac](terraform-vs-iac) | Terraform vs Kubernetes, Ansible, Crossplane — deeper comparisons |
| [02-fundamentals](02-fundamentals) | Providers, versions, multiple providers |
| [03-core-workflow](03-core-workflow) | init, validate, plan, apply, destroy, fmt |
| [04-configuration](04-configuration) | Language: resources, variables, types, expressions, lifecycle, conditions |
| [05-modules](05-modules) | Sources, scope, composition, versions |
| [06-state](06-state) | Backends, locking, remote state, drift, `moved` / `removed` |
| [07-maintain](07-maintain) | Import, state ops, logging, console, test |
| [08-hcp-terraform](08-hcp-terraform) | Hosted runs, workspaces, governance, CLI `cloud` block |
| [labs/local-stack](labs/local-stack) | End-to-end lab without cloud credentials |
| [practice](practice) | Self-check questions |

Examples mostly use `terraform_data`, `hashicorp/random`, `hashicorp/local`, and `hashicorp/tls`. Cloud provider snippets are labeled for syntax recognition; they are not hands-on labs unless you bring your own account.

## Suggested path through the repo

1. Skim [new-in-004.md](00-before-the-exam/new-in-004.md) if HCP Terraform or 4f–4h are new to you.
2. Work through [01](01-infrastructure-as-code) → [03](03-core-workflow) for vocabulary and workflow.
3. Spend real time in [04-configuration](04-configuration) with the `.tf` files open — configuration is where details matter day to day.
4. Add [05-modules](05-modules) and [06-state](06-state); most production surprises live there.
5. [07-maintain](07-maintain) and [08-hcp-terraform](08-hcp-terraform) when you operate in a team or on HCP.
6. Optional: [practice/questions.md](practice/questions.md) closed-book, then [answers.md](practice/answers.md).
7. Broaden context: [terraform-vs-iac](terraform-vs-iac/README.md) once `01`–`06` vocabulary (state, modules, variables) is familiar — maps exam concepts to Crossplane and peers.

## Disclaimer

Community material — **not** affiliated with or endorsed by HashiCorp. Practice questions are **original**, not copied from the certification exam.

Terraform®, HashiCorp®, and HCP Terraform™ are trademarks of HashiCorp.

## License and contributing

[MIT License](LICENSE). [CONTRIBUTING.md](CONTRIBUTING.md).

Before your first `git push`, run `terraform fmt -recursive` and confirm no `*.tfstate` or `.terraform/` is tracked ([.gitignore](.gitignore)). [PUBLISHING.md](PUBLISHING.md).
