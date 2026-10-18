# 6 — Terraform state management

State was introduced in [2d](../02-fundamentals/02d-state). This objective is where it lives, how it is locked, and how you repair it when the configuration is renamed or the real infrastructure drifts.

| Note | Objective |
|---|---|
| [06a-local-backend](06a-local-backend) | The default backend |
| [06b-locking](06b-locking) | Locks during write |
| [06c-remote-backend](06c-remote-backend) | The `backend` block |
| [06d-drift-and-refactor](06d-drift-and-refactor) | Drift, `moved`, `removed` |

```bash
cd 06-state/06a-local-backend
terraform init && terraform apply
```
