# 6a — The local backend

Docs: [Backend block](https://developer.hashicorp.com/terraform/language/v1.12.x/backend), [local backend](https://developer.hashicorp.com/terraform/language/v1.12.x/backend/local).

A backend decides where state is stored and where apply runs. The local backend stores state as a file on the machine where you run Terraform, and it runs every operation on that machine.

If you omit the `backend` block entirely, Terraform uses the local backend with the path `terraform.tfstate` in the working directory. Writing the block out loud changes nothing except the path you choose:

```hcl
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

`path` is relative to the working directory. The lock file next to it is `.terraform.tfstate.lock.info` while an operation holds the lock.

## What local is good for

Learning, and a single person destroying a lab the same day. This study repo uses it on purpose so the examples apply with no account.

## What local is bad for

A team. The state file is a secret-bearing JSON file with no history, and two people applying at once depend on a lock that only works on that one filesystem. Commit the `.tf` files. Do not commit `terraform.tfstate`. Use a remote backend or HCP Terraform once more than one person runs apply. Benefits of migrating (shared state, locking, encryption at rest on S3/GCS/Azure): [6c — why migrate](../06c-remote-backend#why-migrate-from-local-to-remote-exam-benefits) and [8d](../../08-hcp-terraform/08d-cli-integration).

## CLI workspaces and the local backend

`terraform workspace` stores a separate state file per workspace so one configuration can be applied twice (dev and prod) without the two copies sharing a state.

```bash
terraform workspace list
terraform workspace new dev
terraform workspace select dev
```

With the local backend, the `default` workspace uses `terraform.tfstate`. Every other workspace uses `terraform.tfstate.d/<name>/terraform.tfstate`.

Inside configuration, `terraform.workspace` is the name, so a file or a tag can include it:

```hcl
content = terraform.workspace
```

CLI workspaces are a state-path feature. They are not HCP Terraform workspaces. They do not create variables, permissions, or separate credentials. Forgetting which workspace is selected is a common way to apply to the wrong state. `terraform workspace show` before apply.

HCP Terraform's `cloud` integration does not use these CLI workspaces. Switching environments there means selecting a different HCP Terraform workspace. Full comparison: [cli-workspaces-vs-hcp-workspaces.md](../cli-workspaces-vs-hcp-workspaces.md).

## Apply

```bash
cd 06-state/06a-local-backend
terraform init
terraform apply
terraform workspace show
ls -l terraform.tfstate
```

Init with an explicit local backend prints that it is configuring the backend. The state file appears after apply, not after init.
