# 1b — Advantages of IaC patterns

Docs: [Why Terraform](https://developer.hashicorp.com/terraform/intro#why-terraform), [Infrastructure as Code in a private or public cloud](https://www.hashicorp.com/blog/infrastructure-as-code-in-a-private-or-public-cloud).

These are the advantages questions paraphrase. Learn them as outcomes, not as slogans.

**The definition is reviewable.** A change to infrastructure is a diff in Git. Someone else can read it before it runs. The history of who changed the CIDR, and when, is the commit log.

**The result is repeatable.** The same configuration applied in another account or region produces the same shape. Environments stop being hand-built snowflakes that nobody can recreate.

**The workflow is shared.** `init`, `plan`, `apply` is the same for a DNS record and for a Kubernetes cluster. New teammates learn one workflow.

**Drift becomes visible.** If someone edits a security group in the console, the next `plan` shows the difference. The code is the baseline. See [6d](../../06-state/06d-drift-and-refactor).

**Speed comes from reuse.** A module captures a pattern once. Callers pass variables. See [objective 5](../../05-modules).

**Risk is visible before the change.** `plan` prints creates, updates, and destroys. That preview is the main reason teams adopt Terraform over applying changes by hand.

## What Terraform adds on top of "just IaC"

- A single language and workflow across many providers.
- A graph so independent resources are created in parallel, and dependent ones wait.
- State, so Terraform updates the object it created last time instead of creating a second one.
- A plan you can save and apply later, unchanged (`terraform plan -out=tfplan`).

## Advantages a question might list that are false

Terraform does not automatically keep infrastructure correct between applies. Drift detection in HCP Terraform reports drift. Reconciliation still takes an apply, unless you have a separate process that applies.

Terraform does not encrypt secrets just because they live in a variable. See [4h](../../04-configuration/04h-sensitive-data).

Terraform does not require you to write a provider to manage a new resource type if the provider already exists. You write HCL. Providers are published on the [Terraform Registry](https://registry.terraform.io/).
