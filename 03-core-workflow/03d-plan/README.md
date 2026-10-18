# 3d — Generate and review an execution plan

Docs: [terraform plan](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/plan), [resource graph](https://developer.hashicorp.com/terraform/internals/v1.12.x/graph).

`terraform plan` refreshes state, compares the configuration to that state, and prints the actions it would take. It does not perform those actions.

```bash
terraform plan
terraform plan -out=tfplan
terraform plan -var="filename=renamed.txt"
terraform plan -destroy
terraform plan -refresh-only
terraform plan -target=random_pet.server
terraform plan -replace=random_pet.server   # include a forced replacement in the diff
```

`-replace=ADDRESS` marks one resource instance for **replacement** in this plan even if the configuration unchanged. Use it to preview what `terraform apply -replace=...` will do. You can pass `-replace` more than once. Details: [3e](../03e-apply).

## How to read the diff

```text
# random_pet.server will be created
+ resource "random_pet" "server" {
    + id        = (known after apply)
    + length    = 2
  }

# local_file.unit will be updated in-place
~ content = "hello" -> "hello world"

# local_file.unit must be replaced
-/+ resource "local_file" "unit" {
      ~ filename = "old.txt" -> "new.txt" # forces replacement
    }
```

| Symbol | Action |
|---|---|
| `+` | create |
| `-` | destroy |
| `~` | update in place |
| `-/+` | destroy, then create (default replacement) |
| `+/-` | create, then destroy (`create_before_destroy`) |
| `<=` | read a data source |

`(known after apply)` means the provider will assign the value during apply. The plan can still be saved. Downstream resources that need that value wait until apply.

An attribute comment `# forces replacement` means changing it destroys the object. Renaming `filename` on `local_file` forces replacement because the filename is the identity of the file.

## Refresh is part of plan

Unless you pass `-refresh=false`, plan reads every managed object and writes the discovered attributes into state. The official sample asks which commands refresh state unless you add flags: `terraform plan` and `terraform apply`.

**`terraform plan -refresh-only`** reads real infrastructure and prints what **would** change in state — it does **not** write state. **`terraform apply -refresh-only`** performs the refresh and **updates state**. Neither proposes create/update/destroy from configuration. Command matrix: [commands-config-infra-state.md](../commands-config-infra-state.md).

## Saved plans

`-out=tfplan` writes a binary plan. `terraform apply tfplan` applies exactly those actions and skips the approval prompt. `terraform show tfplan` prints it. The file can contain sensitive values.

If configuration or variables change after the plan was saved, apply of that file still uses the saved actions. Generate a new plan when the configuration changed and you want the new diff.

## Targeting

`-target=random_pet.server` plans only that resource and anything it must depend on. HashiCorp documents targeting as a last resort for exceptional repair. A targeted apply can leave state matching a slice of the configuration, so the next full plan has more work. You should recognize the flag, and you should recognize that normal workflow plans the whole configuration.

## The graph underneath

Plan walks the dependency graph. References create edges. Independent resources are planned together. `terraform graph` dumps the graph. You cannot tell Terraform to create `B` before `A` if `A` references `B`; that cycle is an error. Fix the reference or, rarely, break the cycle with a separate apply. See [4f](../../04-configuration/04f-dependencies-and-lifecycle).
