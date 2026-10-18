# `local_file.unit` in this lab

Personal deep-dive on the last resource in [main.tf](main.tf). The objective note is [README.md](README.md).

## The block

```hcl
resource "local_file" "unit" {
  filename = "${path.module}/rendered.txt"
  content  = local.rendered
}
```

## What it does

`local_file` comes from the **`hashicorp/local`** provider. On **apply**, Terraform ensures a file exists on the machine where the CLI runs:

| Argument | Role |
|---|---|
| `filename` | Full path to the file on disk. |
| `content` | Entire body of that file. |

Here, `content` is not a literal string. It is **`local.rendered`**, built in the same file with `templatefile("${path.module}/unit.tftpl", { ... })` from `upper_names` and `primary`. This block is the step that **writes the result of the expression exercises** to disk.

`filename` uses **`path.module`**, the directory that contains this `.tf` file (`04e-expressions-and-functions`). The output is always `rendered.txt` next to the config, regardless of your shell’s current working directory when you run `terraform apply`.

## Dependency graph

1. **`local.rendered`** is evaluated at plan time from variables, `for` expressions, `lookup`, and `templatefile`. No cloud or `local` provider API is involved yet.
2. **`local_file.unit`** depends on that value because `content = local.rendered` references it.
3. **`random_pet.named`** does not feed this file in the current template. Pets and the file can be planned in parallel.

After apply, state holds `local_file.unit` with attributes such as `filename`, `content`, and `id`. If you change `var.names`, `var.regions`, or [unit.tftpl](unit.tftpl), `local.rendered` changes → the plan usually shows an **in-place update** (`~` on `content`). Changing **`filename`** often **forces replacement**, because the path is part of the resource identity (same idea as in [03d-plan](../../03-core-workflow/03d-plan)).

## Exam-relevant ideas

- **Type prefix → provider:** `local_file` → provider `local` (text before the first `_`).
- **Expressions in arguments:** Both `filename` and `content` are computed values.
- **`path.module`:** Prefer it over hard-coded paths when reading or writing files in a module directory.
- **Drift:** Editing `rendered.txt` by hand makes the next plan show a diff; apply reconciles back to `local.rendered`.
- **Where it runs:** The file is created on the **host running Terraform** (laptop, CI worker). It is not “in AWS” unless that is where the CLI runs.

## Why this lab uses it

`local_file` keeps the 4e example **offline**: you can practice `templatefile`, `for`, and `lookup` without cloud credentials. Production configs rarely use `local_file` for app delivery; object storage, secrets managers, or provider-native resources are the norm. For Associate prep, the pattern matters: **compute with locals/functions → pass into a resource argument → state records the outcome.**

For `local-exec`, other `local` resources, and how they differ from provisioners, see [local-provider-and-provisioners.md](local-provider-and-provisioners.md).
