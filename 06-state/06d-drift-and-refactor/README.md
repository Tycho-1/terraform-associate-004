# 6d — Drift and state refactoring

Docs: [Terraform state](https://developer.hashicorp.com/terraform/language/v1.12.x/state), [refactor state](https://developer.hashicorp.com/terraform/language/v1.12.x/state/refactor), [manage drift](https://developer.hashicorp.com/terraform/tutorials/state/resource-drift), [refresh-only](https://developer.hashicorp.com/terraform/tutorials/state/refresh), [moved](https://developer.hashicorp.com/terraform/language/v1.12.x/block/moved), [removed](https://developer.hashicorp.com/terraform/language/v1.12.x/block/removed).

Drift is any difference between the last state Terraform wrote and the real object. Someone edited a tag in the console, or a controller scaled a replica count, or a resource was deleted by hand.

The next `terraform plan` refreshes first, so the diff includes that drift. Terraform's default response is to change the real object back to the configuration. That is usually what you want. Sometimes the outside change is the one you want to keep.

## Three ways to handle drift

**Adopt the outside change into code.** Edit the `.tf` file so it matches reality, then plan. The diff shrinks because configuration, state, and reality agree.

**Adopt the outside change into state only.** Use **`terraform plan -refresh-only`** to **preview** state updates from drift; use **`terraform apply -refresh-only`** to **write** those updates into state. Neither mode changes real infrastructure to match configuration. `plan -refresh-only` alone does **not** modify state — only **apply -refresh-only** does.

**Rule:** `-refresh-only` syncs **state ↔ real infrastructure** only. Your **configuration does not drive** create/update/destroy for that run (exam wording: `.tf` does not play a role in *reconciling* infra). Matrix: [commands-config-infra-state](../../03-core-workflow/commands-config-infra-state.md).

**Ignore a field on purpose.**

```hcl
lifecycle {
  ignore_changes = [tags]
}
```

Terraform sets `tags` on create and then stops planning changes to it. The console can edit tags without the next apply reverting them. `ignore_changes` does not hide drift on every other argument.

`terraform refresh` still exists. The supported command is `terraform apply -refresh-only`, because it goes through the same plan and approval path as other state writes.

## When to use `moved` (exam scenarios)

A **`moved` block** updates **state addresses** so Terraform treats the **same remote object** as living at a new name. It does **not** change the provider resource **type** in the cloud.

| Scenario | Use `moved`? |
|---|---|
| **Renaming** a resource (`random_pet.server` → `random_pet.renamed`) | **Yes** |
| **Moving** a resource into a **module** (`random_pet.server` → `module.pet.random_pet.this`) | **Yes** |
| **Refactoring** addresses **without** destroy/recreate (no downtime for that object) | **Yes** — that is the point |
| **Changing resource type** (`aws_instance` → `aws_launch_template`, or `random_pet` → `random_id`) | **No** — different type = different API object; plan **destroy + create** (or `-replace`) |

`moved` only rewires **where state points**. If the **type** string in the `resource` block changes to something the provider treats as a new kind of object, Terraform cannot “move” the old instance across types.

Imperative equivalent: `terraform state mv` (prefer `moved` in code so the plan shows the rename). Not the same as **`import`** (adopt existing infra) or **`removed`** (drop from state).

## Renaming without destroy: moved

If you rename `random_pet.server` to `random_pet.renamed` and apply, Terraform sees a resource to destroy and a resource to create. The pet name changes. A `moved` block tells Terraform it is the same object.

```hcl
moved {
  from = random_pet.server
  to   = random_pet.renamed
}
```

The plan says "has moved to" instead of destroy and create. State addresses are updated. The real object stays.

`from` and `to` can cross modules:

```hcl
moved {
  from = random_pet.server
  to   = module.pet.random_pet.this
}
```

You can chain moves across refactors. After the new address is applied everywhere, you may delete the `moved` block. Leaving it is harmless: a `from` address that is not in state is ignored.

`terraform state mv random_pet.server random_pet.renamed` does the same edit imperatively, with no review in a plan. Prefer `moved` so the rename is code.

## Forgetting an object without destroying it: removed

Deleting a `resource` block plans a destroy. When the object should survive (it moved to another tool, or you imported it by mistake), declare that:

```hcl
removed {
  from = random_pet.obsolete

  lifecycle {
    destroy = false
  }
}
```

`destroy = false` removes it from state and leaves the real object. `destroy = true` destroys it, which is also what would happen if you only deleted the resource block. The point of `removed` is to make the choice explicit in review.

`terraform state rm random_pet.obsolete` is the imperative form of `destroy = false`.

**`terraform state rm` in one sentence:** drops the address from **state** only; **does not destroy** the live object; Terraform **stops tracking** it. If configuration still declares that resource, a later apply may **create a duplicate** unless you **import** the existing object or **remove** the block from configuration (with an explicit `removed` / destroy choice). Details: [7b](../../07-maintain/07b-inspect-state).

## Try the move

This folder's first address is `random_pet.server`. Apply it, then follow the comments in `main.tf`: the commented `moved` block and the renamed resource are the second step. Doing both in the same edit you can practice on a branch of the file.

```bash
cd 06-state/06d-drift-and-refactor
terraform init
terraform apply
terraform state list
```

To see drift with a local file, apply [04a](../../04-configuration/04a-resources-and-data), edit `unit.txt` in an editor, and run `terraform plan`. The plan shows a change back to the configuration's `content`. `terraform apply -refresh-only` records the edited content into state instead.
