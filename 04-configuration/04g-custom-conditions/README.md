# 4g — Custom conditions

**New in 004.** Exam 003 did not have this objective. HashiCorp lists it as validating configuration with custom conditions. Index: [new-in-004.md](../../00-before-the-exam/new-in-004.md).

Docs: [Validate your configuration](https://developer.hashicorp.com/terraform/language/v1.12.x/validate), [checks tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/checks), [custom conditions tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/custom-conditions).

Custom conditions are assertions you write. The exam question is almost always "does this failure stop the run, or warn?"

| Construct | Since | When | On failure |
|---|---|---|---|
| `validation` on a variable | 0.13 | while building the plan | error, the run stops |
| `precondition` | 1.2 | before the enclosing action | error, the run stops |
| `postcondition` | 1.2 | after the enclosing action | error, the run stops |
| `check` / `assert` | 1.5 | last step of plan and of apply | warning, the run continues |

On a laptop, `check` only runs when **you** run `plan` or `apply`. In **HCP Terraform**, **health assessments** run in the **background** on a schedule (no manual plan required). One part of an assessment is **continuous validation**: re-run your `check` blocks and raise a health alert on failure — useful for HTTP status, certificate expiry, and similar live checks. Drift detection is the other part (console changes vs state). Neither blocks an in-flight apply. See [8b — Health assessments](../../08-hcp-terraform/08b-collaboration-governance#health-assessments).

## Variable validation

```hcl
variable "name" {
  type = string

  validation {
    condition     = length(var.name) > 2
    error_message = "Name must be longer than 2 characters."
  }
}
```

`condition` must be a bool. `error_message` must be a whole sentence: it starts with a capital letter and ends with a period or question mark. A bare `"bad name"` is rejected by Terraform.

On Terraform 1.12 a validation may refer to other variables in the same module. It should still be a check of the inputs, decidable at plan time. Referring to a resource attribute that is only known after apply does not belong here; that is a postcondition.

Multiple `validation` blocks on one variable all have to pass.

## Preconditions and postconditions

They sit inside `lifecycle` on a `resource`, a `data` source, or an `output`. See the full `lifecycle` cheat sheet (all six argument types): [lifecycle-block-reference.md](../lifecycle-block-reference.md).

```hcl
resource "terraform_data" "server" {
  input = var.name

  lifecycle {
    precondition {
      condition     = length(var.name) > 2
      error_message = "Name must be longer than 2 characters."
    }

    postcondition {
      condition     = self.output != null
      error_message = "Server data produced no output."
    }
  }
}
```

### Preconditions — timing and `count`

A **precondition** on a resource is evaluated **before Terraform performs that resource’s planned action** (create, update, or destroy). The condition must **pass** before that instance can proceed. On failure Terraform returns an **error** and the run stops (unlike a `check`).

When the resource uses **`count`** or **`for_each`**, Terraform treats **each instance separately** and evaluates the precondition **once per instance** (`aws_instance.web[0]`, `aws_instance.web[1]`, …).

Preconditions may reference values that are **unknown until apply** (for example another resource’s `id`). Terraform **defers** evaluation until those values are known, then enforces the rule at the right point in the walk. That is why a precondition can guard on apply-time facts that **variable `validation`** cannot use.

Use preconditions for assumptions about the rest of the configuration: "this module was given a private subnet", "the AMI id is non-empty before we create the instance."

### Postconditions — timing and dependents

A **postcondition** runs **after** the object is applied or read (for a `data` source). Inside the block, **`self`** is that object’s attributes. Use it to assert guarantees: "the security group id is non-empty", "the returned architecture is x86_64."

A single resource may define **both** `precondition` and `postcondition` blocks in the same `lifecycle` (and multiple blocks of each type).

If a **postcondition fails**, the apply for that object has already happened, Terraform records the result in state, and the run **fails**. **Dependent resources do not proceed** as if the step succeeded — downstream work that relied on a satisfied postcondition is blocked until you fix the configuration and apply again.

### Outputs and data sources

Outputs can have **preconditions** only (fail early when a caller’s inputs are an illegal combination). `data` sources may use preconditions and postconditions on read, the same lifecycle pattern as resources.

## Check blocks

Among custom conditions, **`check` is the only one Terraform treats as intentionally non-blocking.** Variable `validation`, `precondition`, and `postcondition` are for **strict enforcement** — a failed assert **stops** the run. A failed `check` assert is a **warning**; plan and apply still succeed.

**When it runs:** Terraform evaluates `check` blocks as the **last step** of a **plan** and again as the **last step** of an **apply** — after the main work for that command (resources have been **planned** on `plan`, or **provisioned** on `apply`). That timing is why checks fit **ongoing health and monitoring** (endpoint up, drift from a naming policy, etc.) rather than “this change must not proceed.”

```hcl
check "demo_naming_policy" {
  assert {
    condition     = var.name == "api"
    error_message = "Demo check: this lab expects name=api. Validation still passed."
  }
}
```

A check can contain nested `data` blocks that only exist for the assertion (an HTTP health check, for example). Those data sources are not part of the resource graph the same way top-level data sources are.

Use a **postcondition** when a broken guarantee should **stop** the change. Use a **check** when you want **observation** without blocking the run that might be fixing the problem (or when HCP Terraform re-runs checks on a schedule for continuous validation).

## See a failure

This folder's configuration is valid. Two small demos:

**Validation stops the run** (error):

```bash
cd 04-configuration/04g-custom-conditions
terraform init
terraform apply
terraform plan -var='name=no'
```

`name=no` is two characters, so the variable **validation** fails and nothing is planned.

**Check warns but apply continues** (warning):

```bash
terraform apply -var='name=app' -auto-approve
```

`app` passes **validation** (length and output precondition: starts with `a`). The **`check "demo_naming_policy"`** assert fails because `name != "api"`. Terraform prints a **warning**; the run still **succeeds** and updates resources. That is the exam difference from `validation` / `precondition` / `postcondition`.

The validation rule is automated in `tests/validation.tftest.hcl`. Run `terraform test` from this directory after `init`. See [07e-terraform-test](../../07-maintain/07e-terraform-test).
