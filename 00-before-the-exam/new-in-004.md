# New in exam 004

HashiCorp's [learning path](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-study-004) lists what 004 adds compared with exam 003. Those items live in this repo as normal objective notes. This page is the index.

004 tests **Terraform 1.12**. It includes **HCP Terraform** content. Exam 003 did not.

## Four new topics

| Objective | What 004 adds | Note in this repo |
|---|---|---|
| **4f** | `depends_on` and `create_before_destroy` | [04f-dependencies-and-lifecycle](../04-configuration/04f-dependencies-and-lifecycle) |
| **4g** | Validate configuration with custom conditions | [04g-custom-conditions](../04-configuration/04g-custom-conditions) |
| **4h** | Ephemeral values and write-only arguments | [04h-sensitive-data](../04-configuration/04h-sensitive-data) |
| **8c** | Organize and use HCP Terraform workspaces and projects | [08c-workspaces-and-projects](../08-hcp-terraform/08c-workspaces-and-projects) |

## HCP Terraform

Objective 8 is the HCP Terraform content 004 includes. 8c is the sub-objective HashiCorp calls out as new. The rest of objective 8 is in the exam for the same reason: the hosted product is now in scope.

| Note | Covers |
|---|---|
| [08a-create-infrastructure](../08-hcp-terraform/08a-create-infrastructure) | Organizations, workspaces, remote runs |
| [08b-collaboration-governance](../08-hcp-terraform/08b-collaboration-governance) | Teams, policy, health, dynamic credentials, registry, explorer |
| [08c-workspaces-and-projects](../08-hcp-terraform/08c-workspaces-and-projects) | Projects, variable sets, run triggers |
| [08d-cli-integration](../08-hcp-terraform/08d-cli-integration) | `terraform login` and the `cloud` block |

## What to be able to say

**4f.** A reference such as `random_pet.server.id` is already a dependency. `depends_on` is the extra edge, used when no reference exists. Default replacement is destroy-then-create (`-/+`). `create_before_destroy = true` flips that to create-then-destroy (`+/-`).

**4g.** `validation`, `precondition`, and `postcondition` stop the run when the condition is false. A `check` block warns and the run continues.

**4h.** `sensitive = true` only redacts CLI and UI output. The value is still plaintext in state. An ephemeral value is omitted from the plan and from state. A write-only argument (`password_wo`) is sent to the provider and not stored. Bump `password_wo_version` to rotate it, because Terraform cannot diff a value it does not store. The same note also covers Vault, which is the rest of objective 4h on the [content list](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004).

**8c.** An HCP Terraform workspace holds one state. A project groups workspaces so permissions and variable sets can be granted once. Variable precedence, highest first: workspace variables, then variable sets on that workspace, then variable sets on its project, then organization-wide variable sets. A run trigger queues a run in a downstream workspace after the source workspace applies successfully. That is separate from `terraform workspace`, which is a CLI state-file feature. Comparison: [cli-workspaces-vs-hcp-workspaces.md](../06-state/cli-workspaces-vs-hcp-workspaces.md).

## Practice that targets this page

These questions in [practice/questions.md](../practice/questions.md) are the 004 delta: 2, 5, 7, 15, 16, 22, 23, 24, 27, 30, 31, 32.
