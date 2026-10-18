# 4f — Dependencies and lifecycle

**New in 004.** Exam 003 did not have this objective. HashiCorp lists it as `depends_on` and `create_before_destroy`. Index: [new-in-004.md](../../00-before-the-exam/new-in-004.md).

Docs: [depends_on](https://developer.hashicorp.com/terraform/language/v1.12.x/meta-arguments/depends_on), [lifecycle](https://developer.hashicorp.com/terraform/language/v1.12.x/meta-arguments/lifecycle), [resource graph](https://developer.hashicorp.com/terraform/internals/v1.12.x/graph).

The content list titles this objective "define resource dependencies." The implicit edge and the lifecycle rules are both in scope.

## Implicit dependencies

A reference is a dependency.

```hcl
resource "local_file" "unit" {
  content = random_pet.server.id
}
```

Terraform creates `random_pet.server` first. It destroys `local_file.unit` first. You do not write that order.

Use a reference whenever the downstream block actually uses a value. That gives Terraform the most precise edge, and the plan can show the value flowing through.

## depends_on

`depends_on` adds an edge when nothing in the arguments refers to the other resource, but the other resource still has to exist first. The usual case is a side effect: an IAM policy, a network route, or a null provisioner that must finish before a later resource runs, even though the later resource does not interpolate an attribute.

```hcl
resource "terraform_data" "service" {
  depends_on = [terraform_data.server]
}
```

`depends_on` takes a list of resources or modules. Depending on a module waits for every resource in that module.

Reach for it last. A `depends_on` edge is coarse. It can force resources to wait, and to be recreated, more often than a single-attribute reference would. If you can express the relationship by passing an `id`, do that.

## create_before_destroy

By default, replacement is destroy then create (`-/+` in the plan). That leaves a gap: the old object is gone before the new one exists. Some objects cannot have a gap (a security group that instances still use, a record that must keep resolving).

```hcl
lifecycle {
  create_before_destroy = true
}
```

Terraform creates the replacement first, then destroys the old one. The plan symbol flips to `+/-`.

The provider must allow two copies at once. A resource whose name must be unique (`name = "web"` with no random suffix) cannot exist twice, and `create_before_destroy` fails while both copies would share that name. The usual fix is a name that changes with the replacement, so the new object gets a new unique name.

`create_before_destroy` combined with `prevent_destroy` fails when a replacement is required, because the old object would have to be destroyed and `prevent_destroy` forbids it.

## The rest of lifecycle

Full list of every `lifecycle` argument in one place (including `precondition` / `postcondition`): [lifecycle-block-reference.md](../lifecycle-block-reference.md).

```hcl
lifecycle {
  prevent_destroy       = true
  ignore_changes        = [tags]
  replace_triggered_by  = [terraform_data.token]
}
```

**`prevent_destroy`** — any plan that would destroy this resource errors. You use it on databases and state buckets. Removing the argument requires an apply that itself does not destroy anything; the next plan is then allowed to destroy.

**`ignore_changes`** — Terraform will not update these arguments to match the configuration after the object exists. It still sets them on create. `ignore_changes = all` ignores every argument. People use this when something outside Terraform owns a field (an autoscaler setting a desired count). Drift on an ignored argument disappears from the plan.

**`replace_triggered_by`** — when the listed resource or attribute changes, replace this resource even if its own arguments did not change. A common pattern is a `terraform_data` whose `triggers_replace` holds a token or a script hash.

**`precondition` and `postcondition`** live in this block too. They are objective [4g](../04g-custom-conditions).

## What the plan symbols mean for this objective

| You configured | Replacement symbol |
|---|---|
| default | `-/+` destroy then create |
| `create_before_destroy = true` | `+/-` create then destroy |

Change `revision` in this folder's `terraform.tfvars` and plan. `terraform_data.server` uses `triggers_replace`, so a new revision forces replacement, and `create_before_destroy` makes that replacement `+/-`. `terraform_data.service` lists `depends_on` and is planned after the server.

```bash
cd 04-configuration/04f-dependencies-and-lifecycle
terraform init
terraform apply
# edit revision in terraform.tfvars
terraform plan
```
