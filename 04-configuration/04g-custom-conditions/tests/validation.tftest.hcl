# Run from 04-configuration/04g-custom-conditions:
#   terraform init
#   terraform test

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
