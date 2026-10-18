# `lifecycle` block — all arguments

One-page reference for the **`lifecycle` meta-argument** on resources (and on `data` / `output` for conditions). Objective **4f** covers dependencies and the first lifecycle flags; **4g** covers `precondition` / `postcondition`. Runnable examples: [04f-dependencies-and-lifecycle](04f-dependencies-and-lifecycle), [04g-custom-conditions](04g-custom-conditions).

Docs: [lifecycle](https://developer.hashicorp.com/terraform/language/v1.12.x/meta-arguments/lifecycle).

## Not inside `lifecycle`

**`depends_on`** is a separate **meta-argument** on the resource (sibling to `lifecycle`, not nested inside it). See [04f](04f-dependencies-and-lifecycle).

```hcl
resource "example" "this" {
  depends_on = [other_resource]

  lifecycle { ... }
}
```

## All valid `lifecycle` arguments (Terraform 1.12)

Only these six forms exist. You can combine several in one `lifecycle` block.

```hcl
lifecycle {
  create_before_destroy = true # recreate with minimal downtime (+/- in plan)
  prevent_destroy       = true # block accidental destruction
  ignore_changes        = [ami] # ignore specific attribute drift after create
  replace_triggered_by  = [other_resource] # force replace when another resource changes

  precondition { # validate before create/update/delete on this object
    condition     = ...
    error_message = "..."
  }

  postcondition { # validate after create/update/read on this object
    condition     = ...
    error_message = "..."
  }
}
```

| Argument | Type | What it does |
|---|---|---|
| `create_before_destroy` | bool | On **replacement**, create the new object first, then destroy the old one (`+/-`). Default is destroy then create (`-/+`). |
| `prevent_destroy` | bool | If `true`, any plan that would **destroy** this resource fails (including `terraform destroy`). |
| `ignore_changes` | list of attribute names, or `all` | After create, Terraform does not plan updates to those arguments to match config. Drift on ignored attrs is hidden from the plan. |
| `replace_triggered_by` | list of resource references | Replace **this** resource when a listed resource changes, even if this resource's own arguments did not. |
| `precondition` | nested block (repeatable) | If `condition` is false before the action, **error** — run stops. |
| `postcondition` | nested block (repeatable) | If `condition` is false after the action, **error** — run stops. Use `self` for this object. |

There is no `lifecycle` argument named `validation`. **Variable** validation uses a `validation` block on `variable`, not inside `lifecycle`. See [04g](04g-custom-conditions).

## Short notes per argument

**`create_before_destroy`** — Use when a brief outage during replace is unacceptable (security group still attached, DNS record must resolve). The provider must allow two instances briefly (unique names may need a random suffix). Conflicts with **`prevent_destroy`** when a replace would have to destroy the old instance.

**`prevent_destroy`** — Safety rail for state buckets, production databases. Remove or set to `false` in a plan that only changes the lifecycle block, then apply again before destroy is allowed.

**`ignore_changes`** — Common for `tags` managed elsewhere, or `desired_count` owned by a cluster autoscaler. `ignore_changes = [ami]` means Terraform will not revert an AMI change in the cloud; it also will not apply a new AMI from config until you remove the ignore or taint/replace. Example attribute names depend on the resource type (`ami` on `aws_instance`, not on `local_file`).

**`replace_triggered_by`** — Entries are **resource addresses** (for example `terraform_data.token`, `aws_lambda_function.example`). Often paired with `terraform_data` and `triggers_replace` so a token or config hash forces downstream replacement.

**`precondition` / `postcondition`** — Same `condition` + `error_message` shape as variable `validation`. Failure **stops** the run (unlike `check`, which only warns). **Precondition:** evaluated **before** that resource instance’s planned action; with `count` / `for_each`, **per instance**; may use apply-time unknowns (deferred until known). **Postcondition:** evaluated **after** apply/read; a failure blocks **dependent** resources from continuing. One resource may have both. Full table: [04g](04g-custom-conditions).

## Where `lifecycle` is allowed

| Block | Typical lifecycle use |
|---|---|
| `resource` | All six forms above |
| `data` | `precondition`, `postcondition` (and other lifecycle args where documented) |
| `output` | `precondition` (fail the module output if caller context is invalid) |

`module` blocks do not have a `lifecycle` meta-argument.

## Exam reminders

- **`depends_on`** ≠ `lifecycle`. Both are meta-arguments on the resource.
- **`terraform apply -replace=ADDRESS`** forces replacement without editing config; lifecycle rules still apply (`create_before_destroy`, etc.). See [03e](../03-core-workflow/03e-apply).
- Failed **`check`** → warning (non-blocking; last step of plan/apply). Failed **`precondition` / `postcondition` / `validation`** → error (strict enforcement).
