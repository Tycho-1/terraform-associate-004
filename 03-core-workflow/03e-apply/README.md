# 3e — Apply changes

Docs: [terraform apply](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/apply).

`terraform apply` performs the plan and updates state to record what it did.

```bash
terraform apply                 # plan, prompt, then apply
terraform apply -auto-approve   # skip the prompt
terraform apply tfplan          # apply a saved plan, no prompt, no replanning
terraform apply -refresh-only   # update state from reality, change no infrastructure
terraform apply -replace=random_pet.server   # force destroy+create for one address
```

With no saved plan, apply creates a plan and asks you to type `yes`. `-auto-approve` skips that question. A saved plan file has already been approved by whoever saved it, so apply does not ask again.

## What apply does, from the official sample

Pick the two that are true:

- Terraform makes the infrastructure changes defined in the configuration.
- Terraform updates the state file with the changes it made.

The other sample options are other commands:

- downloading plugins is `terraform init`
- correcting formatting is `terraform fmt`
- apply does not destroy and recreate everything on each run; it changes only what the diff requires

## How the walk works

Terraform walks the graph in dependency order. For each resource it calls the provider, then writes state. A failure halfway through leaves the successful changes recorded. You fix the cause and apply again. Terraform does not roll back the resources that already changed.

State locking is held during apply so a second operation that would **modify state** is **blocked** until the lock is released (the other command errors; it does not overwrite). See [6b](../../06-state/06b-locking).

## Force replacement with `-replace`

Sometimes you need a **new** remote object even though the configuration did not change: a corrupted VM, a provider bug, or an attribute that cannot be updated in place and you do not want to edit `.tf` just to trigger a replace.

Pass **`-replace=ADDRESS`** on `apply` (or on `plan` to preview only). Terraform plans a **replacement** for that instance: default order is destroy then create (`-/+` in the diff). `lifecycle { create_before_destroy = true }` on that resource still applies and can flip the plan to `+/-`.

```bash
terraform plan  -replace=random_pet.server
terraform apply -replace=random_pet.server
terraform apply -replace=random_pet.server -replace=local_file.unit   # repeat the flag
```

Use the full **resource address**, including `module.` prefixes and `for_each` / `count` keys (quote keys in the shell when they contain special characters):

```bash
terraform apply -replace='module.app.random_pet.server["web"]'
```

`-replace` does **not** change your configuration. It affects **only this run** (or the saved plan if you used `plan -replace=... -out=tfplan`). The next ordinary `apply` with unchanged `.tf` does not replace again unless something in config still forces it.

**Exam note:** `terraform taint` is **removed** in current Terraform. The supported imperative replacement is **`apply -replace`** (or `plan -replace`). Do not pick taint on a 004-style question. Changing a **ForceNew** argument in configuration is the declarative way to replace; `-replace` is the operational shortcut. See [3d](../03d-plan) for plan symbols and [4f](../../04-configuration/04f-dependencies-and-lifecycle) for `create_before_destroy`.

## Approval is not a security boundary by itself

`-auto-approve` on a laptop is convenient and dangerous in a shared directory. In automation, prefer `plan -out` plus `apply tfplan` so the applied actions are the ones that were reviewed. HCP Terraform does this as a run: a plan, a policy check, an approval, an apply. See [8a](../../08-hcp-terraform/08a-create-infrastructure).

## Apply a small edit

In [lab](../lab), change `content` from `web` to `api`, then:

```bash
terraform plan
terraform apply
```

The plan shows `~` on `local_file.unit` because `content` can be updated in place, and a replacement of `random_pet` only if you changed an argument that forces a new pet. State's serial increments. `terraform state show local_file.unit` prints the new content.
