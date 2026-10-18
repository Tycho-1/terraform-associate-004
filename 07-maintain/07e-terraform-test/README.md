# 7e — `terraform test` (configuration tests)

Docs: [Tests](https://developer.hashicorp.com/terraform/language/tests), [Command: test](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/test).

`terraform test` runs `.tftest.hcl` files. Each file defines one or more **runs**: usually a `plan` or `apply` in a temporary workspace, then **assert** blocks that must be true, or **expect_failures** when you want a validation or precondition to fail on purpose.

The Associate exam does not list this command. It is the native way to test modules without a cloud account, and it reuses the same ideas as [4g](../../04-configuration/04g-custom-conditions) (`assert` conditions, `expect_failures`).

## How it differs from other checks

| Mechanism | When it runs | Needs cloud credentials? |
|---|---|---|
| `terraform validate` | before plan | no (no API calls) |
| variable `validation` / `precondition` | during plan or apply | only if the plan needs the API |
| `check` block | end of plan or apply | often yes for data-source checks |
| `terraform test` | when you run `terraform test` | no, if you use `mock_provider` and `command = plan` |

`validate` checks syntax and types. Tests run real plan/apply logic against **mocked** providers or a small stack, and assert on the resulting resource addresses and attributes.

## File layout

Tests live in `tests/*.tftest.hcl` next to the module or root module they exercise. `terraform fmt` formats them too. See [3g](../../03-core-workflow/03g-fmt).

```text
04g-custom-conditions/
  main.tf
  tests/
    validation.tftest.hcl
```

## A minimal example in this repo

```bash
cd 04-configuration/04g-custom-conditions
terraform init
terraform test
```

`tests/validation.tftest.hcl` runs `plan` with a valid `name`, then runs `plan` with `name = "no"` and expects the variable validation to fail. That is the same rule you already hit with `terraform plan -var='name=no'`.

## Anatomy of a test file

```hcl
variables {
  name = "api"
}

run "plan_with_valid_name" {
  command = plan
}

run "variable_validation_rejects_short_name" {
  command = plan

  variables {
    name = "no"
  }

  expect_failures = [
    var.name,
  ]
}
```

- **`variables`** at file scope set defaults for every run in that file.
- **`run`** is one scenario. `command` is usually `plan` or `apply`.
- **`variables`** inside a run override those defaults for that run only.
- **`assert`** checks an expression after a successful command. Failure stops the test run.
- **`expect_failures`** lists addresses (resources, variables, outputs) that must fail during plan or apply. Use this to prove a `validation` or `precondition` works.

Assert blocks look like `check` blocks, but they belong to the test run, not to your production configuration:

```hcl
assert {
  condition     = local_file.unit.content != ""
  error_message = "File content must not be empty."
}
```

## Mock providers

Large modules use `mock_provider "azurerm" {}` (or `aws`, `google`) so `plan` can build a graph without calling the real API. The AKS reference platform does this for every module under `modules/*/tests/*.tftest.hcl`. See [reference-platforms.md](../../reference-platforms.md).

```hcl
mock_provider "azurerm" {}

variables {
  location = "westeurope"
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.local_account_disabled
    error_message = "Local accounts must be disabled."
  }
}
```

Mocked plans still evaluate your HCL, `validation`, and `precondition` blocks. They do not prove the cloud will accept the API call. They prove your configuration encodes the policy you intended.

## Commands

```bash
terraform test                    # all .tftest.hcl under this directory
terraform test -filter=valid      # runs whose file or run name matches
terraform test -verbose           # more output per run
terraform test -json              # machine-readable results for CI
```

Tests create a temporary working directory. They do not modify your normal `terraform.tfstate` in the module directory when `command = plan` only. Runs with `command = apply` can create real resources unless everything is mocked; prefer `plan` in module tests.

## Console vs test vs practice questions

- **`terraform console`** — you type one expression and see the value ([07d](../07d-terraform-console)).
- **`terraform test`** — automated runs with assertions, checked in CI.
- **`practice/questions.md`** — multiple-choice exam practice, not executable tests.

## Real-world reference

The unpublished AKS platform runs `terraform test` in CI (`scripts/check.sh`) with mocked Azure providers. That pattern is the production version of the small `validation.tftest.hcl` in [04g](../../04-configuration/04g-custom-conditions).
