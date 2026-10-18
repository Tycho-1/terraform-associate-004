# 3 — Core Terraform workflow

Write configuration, initialize, plan, apply. Format and validate while you write. Destroy when the exercise is over.

| Note | Objective |
|---|---|
| [03a-workflow](03a-workflow) | The workflow as a whole |
| [03b-init](03b-init) | `terraform init` |
| [03c-validate](03c-validate) | `terraform validate` |
| [03d-plan](03d-plan) | `terraform plan` and the graph |
| [03e-apply](03e-apply) | `terraform apply` |
| [03f-destroy](03f-destroy) | `terraform destroy` |
| [03g-fmt](03g-fmt) | `terraform fmt` |
| [commands-config-infra-state.md](commands-config-infra-state.md) | Which commands use `.tf`, real infra, and state |
| [dot-terraform-directory.md](dot-terraform-directory.md) | What `.terraform/` is (not state); Git and permission errors |
| [lab](lab) | A directory you can run end to end |

```bash
cd 03-core-workflow/lab
terraform fmt
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
```
