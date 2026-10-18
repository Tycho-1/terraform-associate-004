# 7d — `terraform console` (interactive expressions)

Docs: [Command: console](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/console).

`terraform console` is a small REPL. You type a Terraform expression and see what it evaluates to, using the same configuration, variable values, and state as a normal run in that directory. It does not change infrastructure and does not write state.

The Associate exam does not list this command. It is useful when you are writing [4e](../../04-configuration/04e-expressions-and-functions) expressions or checking what a reference returns after an apply.

## When to use it

- You are unsure whether `lookup(var.regions, "eu-west-1", "default")` does what you expect.
- You want to see `random_pet.server.id` or `module.pet.name` without opening `terraform.tfstate` by hand.
- You are building a `for` expression or a `templatefile` map and want quick feedback before `terraform plan`.

Use `terraform validate` to check that the whole configuration is well-formed. Use `terraform plan` to see infrastructure changes. Use the console only to experiment with **expressions**.

## Prerequisites

```bash
cd 03-core-workflow/lab
terraform init
terraform apply -auto-approve
terraform console
```

`init` is required so provider schemas and modules are loaded. Resource attributes such as `random_pet.server.id` come from **state**. If you have never applied, many references are empty or unknown.

Variable values load the same way as for `plan`: `terraform.tfvars`, `*.auto.tfvars`, and `TF_VAR_*`.

## Inside the console

The prompt is `>`. Type one expression per line. The result prints on the next line. Leave with `exit` or Ctrl+D.

```text
> var.content
"web"
> random_pet.server.id
"leading-dane"
> "${random_pet.server.id}-${var.content}"
"leading-dane-web"
> length(var.content)
3
> upper(var.content)
"WEB"
> merge({ a = "1" }, { b = "2" })
{
  "a" = "1"
  "b" = "2"
}
> local_file.unit.filename
"/path/to/03-core-workflow/lab/unit.txt"
```

You can use the same references as in configuration: `var.`, `local.`, resources, `data.`, `module.`, functions, and conditionals.

A statement that is not an expression (a full `resource` block) is invalid here. The console evaluates expressions only.

## Flags that matter

```bash
terraform console -var='content=api'
terraform console -var-file=extra.tfvars
terraform console -state=terraform.tfstate.backup
```

`-var` and `-var-file` override variables for this session. `-state` points at a different state file so you can inspect old resource attributes without switching the working backend.

The console does not run `apply` and does not refresh from the cloud by default in the same way `plan` does. What you read from a managed resource is what **state** last recorded. If someone changed the object outside Terraform, run `terraform apply -refresh-only` first, then open the console again. See [7b](../07b-inspect-state) and [6d](../../06-state/06d-drift-and-refactor).

## Console vs other commands

| You want to… | Use |
|---|---|
| Test an expression quickly | `terraform console` |
| Check the whole `.tf` tree for type errors | `terraform validate` |
| See creates, updates, destroys | `terraform plan` |
| Print one resource from state | `terraform state show ADDRESS` |
| Print root outputs | `terraform output` |

`terraform output` only shows declared outputs. The console can evaluate any expression that type-checks in the module, including `module.child.output` paths you are about to wire up.

## Sensitive values

If an expression evaluates to a sensitive value, the console redacts it, the same as `terraform output`. The value is still in state if it came from a normal attribute. See [4h](../../04-configuration/04h-sensitive-data).

## Try it on the complex-types lab

```bash
cd 04-configuration/04d-complex-types
terraform init && terraform apply -auto-approve
terraform console
```

```text
> var.regions["eu-central-1"]
"10.0.0.0/16"
> keys(var.regions)
tolist([
  "eu-central-1",
  "eu-west-1",
])
> [for k, v in var.regions : "${k}=${v}"]
tolist([
  "eu-central-1=10.0.0.0/16",
  "eu-west-1=10.1.0.0/16",
])
```

That is the fastest way to confirm map indexing and `for` syntax before you paste them into a `resource` block.
