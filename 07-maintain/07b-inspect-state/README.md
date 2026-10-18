# 7b — Inspect state with the CLI

Docs: [state command](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/state), [manage resources in state](https://developer.hashicorp.com/terraform/tutorials/state/state-cli).

These commands read or edit state. They do not change infrastructure, except where a later apply reacts to the edit you made.

Apply any lab first so the commands have a state to read. [03-core-workflow/lab](../../03-core-workflow/lab) is enough.

```bash
cd 03-core-workflow/lab
terraform apply -auto-approve

terraform state list
terraform state show random_pet.server
terraform state show local_file.unit

terraform show
terraform show -json | head
terraform output
terraform output -raw filename
```

## What each one prints

| Command | Prints |
|---|---|
| `terraform state list` | addresses, one per line (`random_pet.server`, `module.pet.random_pet.this`) |
| `terraform state list local_file.unit` | that address, if it is in state |
| `terraform state show ADDRESS` | attributes of one resource, as HCL-like text |
| `terraform show` | the whole state in a readable form, or a saved plan if you pass the plan file |
| `terraform show tfplan` | a saved plan |
| `terraform output` | **root module** outputs only; child module outputs are not listed (use `module.x.y` in root config or re-export); sensitive values redacted |
| `terraform output -json` | root outputs as JSON, sensitive values included |
| `terraform state pull` | raw remote or local state JSON on stdout |
| `terraform console` | interactive REPL; evaluate expressions using config and state (not a state dump) |

`terraform show` with no arguments reads state. `terraform show tfplan` reads a plan file. The same command does both jobs.

## Filters

`terraform state list` accepts a filter address. Module instances and `for_each` keys need quotes in the shell:

```bash
terraform state list 'module.pet.*'
terraform state show 'local_file.unit["eu-central-1"]'
```

## Edits, and the declarative replacements

| Imperative | Prefer |
|---|---|
| `terraform state mv OLD NEW` | a `moved` block |
| `terraform state rm ADDRESS` | a `removed` block with `destroy = false` (see below) |
| `terraform state replace-provider OLD NEW` | when a provider source address changes; there is no block equivalent you need for the exam |
| `terraform apply -replace=ADDRESS` (or `plan -replace`) | one-off forced replacement; `terraform taint` is removed — use `-replace` instead |

### What `terraform state rm` does (exam)

**`terraform state rm`** removes a resource **from state only**. It does **not** delete or destroy the real infrastructure object in the cloud (or on disk for `local_file`). The provider is **not** asked to destroy anything.

After removal, Terraform **no longer tracks** that object. If the **`resource` block is still in your configuration**, the next **`plan` / `apply`** typically tries to **create** a new object at that address (Terraform thinks nothing exists yet). To manage the existing object again, **`import`** it (or use an `import` block). To stop managing it but keep the real resource, use **`removed`** with `destroy = false` or remove the `resource` block **and** use `removed` / `state rm` so you do not accidentally plan a destroy.

`state rm` does not refresh from the API; it only edits the state file (local or remote).

`terraform state push` overwrites remote state with a local file. It is a recovery tool. It is not part of the normal workflow, and a wrong file is a bad day. `terraform state pull` first if you are about to push.

None of these refresh from the cloud. `state show` prints what state currently says. If you need state to match the console, that is `terraform apply -refresh-only`, then `state show` again.

## Check

```bash
cd 03-core-workflow/lab
terraform state list
terraform state show random_pet.server
```

`id` on the pet is the generated name. That is the mapping from [2d](../../02-fundamentals/02d-state): the address is `random_pet.server`, the remote identity is the `id` attribute.
