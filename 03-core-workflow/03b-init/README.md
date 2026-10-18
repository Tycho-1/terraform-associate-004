# 3b — Initialize a working directory

Docs: [terraform init](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/init), [lock file](https://developer.hashicorp.com/terraform/language/v1.12.x/files/dependency-lock).

`terraform init` prepares a working directory so the other commands can run. It:

- downloads and installs provider plugins into `.terraform/providers` (from the public registry by default, or from a private registry, filesystem mirror, or network mirror when the CLI config says so; see [2a](../../02-fundamentals/02a-provider-versions))
- downloads modules into `.terraform/modules`
- writes or updates `.terraform.lock.hcl`
- configures the backend and, when you ask, migrates state into it
- creates an empty state on the first real apply, not during init itself

Init does not create infrastructure. A question that says "init provisions the servers" is wrong.

## Flags you should recognize

| Flag | When |
|---|---|
| `-upgrade` | select the newest provider versions the constraints allow and update the lock file |
| `-migrate-state` | copy existing state into a backend you just changed |
| `-reconfigure` | forget the previous backend settings and use the current ones, without migrating |
| `-backend-config=FILE` or `-backend-config='key=value'` | supply backend arguments that are not in the `.tf` files |
| `-get-plugins=false` | skip provider installation (rare; init still wires the backend) |

Changing the `backend` block and running a plain `init` makes Terraform stop and tell you the backend changed. It will not silently point at a new state location. You choose migrate or reconfigure.

## Backend configuration has no variables

This belongs to objective 6 and it surfaces during init:

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state" # a literal. var.bucket is a syntax error here
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}
```

Partial configuration omits the secret parts from the file and passes them at init time:

```bash
terraform init -backend-config="bucket=my-terraform-state"
```

## A working directory remembers the backend

Init writes backend settings under `.terraform/`. Copying a directory to another machine without `.terraform/` is fine: the next init rebuilds it. Copying `.terraform/` between machines is unnecessary and can point at the wrong backend.

For a longer explanation of everything under `.terraform/` (providers, modules, vs `terraform.tfstate`, Git, permission errors), see [dot-terraform-directory.md](../dot-terraform-directory.md).

## Check

From [lab](../lab):

```bash
terraform init
ls .terraform/providers
test -f .terraform.lock.hcl && echo "lock file written"
```
