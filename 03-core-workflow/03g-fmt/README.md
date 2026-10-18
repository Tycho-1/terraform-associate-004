# 3g — Format and style

Docs: [terraform fmt](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/fmt), [Google Cloud style and structure](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure).

`terraform fmt` rewrites Terraform files in the working directory to a canonical style: two-space indentation, aligned equals signs, one standard placement of arguments and blocks.

```bash
terraform fmt                 # current directory
terraform fmt -recursive      # this directory and subdirectories
terraform fmt -check          # change nothing, exit non-zero if a file is non-canonical
terraform fmt -diff           # show the diff
terraform fmt -check -recursive
```

`-check` is the CI form. The exit code is `0` when every file is already formatted and `3` when fmt would have changed something.

## What fmt will not do

It does not validate types, does not contact a provider, and does not change the meaning of the configuration on purpose. It is whitespace and layout. A question that says "fmt fixes an unknown attribute" is describing `validate`.

Fmt reads `.tf` and `.tfvars` files. It also formats `.tftest.hcl` in current Terraform. It does not format JSON configuration (`.tf.json`); JSON has its own formatter.

## Style you will see in every example

```hcl
resource "random_pet" "server" {
  length = 2
}
```

Arguments use `=` with spaces. Blocks do not. Nested blocks have the same two-space indent. Comments are `#` or `//`. `/* */` works and is rare in Terraform codebases.

HashiCorp's published style is what fmt produces. You do not need a separate style guide for the exam. Run fmt, then read the file. For layout and naming beyond whitespace — file split, resource names, variables, outputs — use Google's [style and structure guide](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure).

## Try it

In [lab/main.tf](../lab/main.tf) the file is already formatted. Break the alignment on purpose, run `terraform fmt -diff`, and confirm the resource arguments did not change, only the spacing.
