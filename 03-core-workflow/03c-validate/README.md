# 3c — Validate a configuration

Docs: [terraform validate](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/validate).

`terraform validate` checks that the configuration is internally consistent: syntax the parser already accepted, attribute types, references to names that exist, and provider schema.

It does not:

- contact a cloud API
- check that credentials work
- refresh or read state
- create or destroy anything
- decide whether an AMI id is real

A configuration can validate and still fail on apply because the cloud rejects it. Validate answers "is this configuration well-formed?", not "will this apply succeed?"

Run `terraform init` first. Validate loads provider schemas from the installed plugins. Without them it cannot know which arguments a resource accepts.

```bash
cd 03-core-workflow/lab
terraform init
terraform validate
```

Success prints `Success! The configuration is valid.`

JSON output (`-json`) is what CI parses. The human output is enough for study.

## Validate vs the other checks

| Command or block | Question it answers |
|---|---|
| `terraform fmt` | Does the file match canonical style? |
| `terraform validate` | Is the configuration internally consistent? |
| `validation` / `precondition` / `postcondition` | Does this value meet a rule I wrote? A failure stops the run. |
| `check` | Does this assertion hold? A failure warns and the run continues. |

Custom conditions are objective [4g](../../04-configuration/04g-custom-conditions). `terraform validate` does not run check blocks against live infrastructure. Checks run at the end of plan and apply.

## A failure worth seeing

Add `unknown = true` inside `resource "random_pet" "server"` in the lab, run `terraform validate`, read the error, then remove the line. The error names the attribute the provider schema does not define. That is the whole job of validate.
