# 7 — Maintain infrastructure with Terraform

Day-2 work: adopt objects Terraform did not create, inspect state, and turn on logs when a run misbehaves.

| Note | Objective |
|---|---|
| [07a-import](07a-import) | Bring an existing object under management |
| [07b-inspect-state](07b-inspect-state) | `state list`, `state show`, `terraform show` |
| [07c-logging](07c-logging) | `TF_LOG` |
| [07d-terraform-console](07d-terraform-console) | `terraform console` — try expressions against real config and state (not on the exam list) |
| [07e-terraform-test](07e-terraform-test) | `terraform test` — `.tftest.hcl` plan/assert tests (not on the exam list) |

Import syntax is in `import.tf.example`. The state commands are real once any lab in this repo has been applied.
