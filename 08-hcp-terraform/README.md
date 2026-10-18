# 8 — HCP Terraform

**New in 004.** Exam 003 did not include HCP Terraform. This whole objective is that content. **8c** is the sub-objective HashiCorp lists as new on its own. Index: [new-in-004.md](../00-before-the-exam/new-in-004.md).

HCP Terraform (formerly Terraform Cloud) is HashiCorp's hosted service. It stores state, runs Terraform, holds variables and credentials, and adds teams, policy, and **health assessments** (scheduled drift detection plus re-running `check` blocks). The CLI you have been using is still the CLI. The service is where state and the run live.

| Note | Objective |
|---|---|
| [08a-create-infrastructure](08a-create-infrastructure) | Organizations, workspaces, runs |
| [08b-collaboration-governance](08b-collaboration-governance) | Teams, policy, health, registry, explorer |
| [08c-workspaces-and-projects](08c-workspaces-and-projects) | **New in 004.** Projects, variable sets, run triggers |
| [08d-cli-integration](08d-cli-integration) | `terraform login` and the `cloud` block |
| [provider-credentials.md](provider-credentials.md) | HCP token vs cloud creds; dynamic `TFC_*` and static env examples |
| [hcp-vs-open-source-cli.md](hcp-vs-open-source-cli.md) | State versions, run history, remote ops, variable sets vs CLI + S3 |
| [hcp-variables-and-tf-var.md](hcp-variables-and-tf-var.md) | HCP Terraform vs env vars; `TF_VAR_*` does not declare variables |

There is no free local substitute for these platform features (open-source CLI + S3 is still “free,” but not the same product). The `.tf.example` files are the configuration you would add to a real organization. Read them next to the notes. Do not `init` them here.

Docs start at [What is HCP Terraform?](https://developer.hashicorp.com/terraform/cloud-docs).
