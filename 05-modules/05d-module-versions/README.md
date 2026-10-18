# 5d — Manage module versions

Docs: [Module version](https://developer.hashicorp.com/terraform/language/v1.12.x/block/module#version).

### Is a version **required**? (exam summary)

| Context | `version` required? | Notes |
|---|---|---|
| **`module` from Terraform Registry** | **No** — optional | Omit → `init` uses **latest** published version at that time |
| **`module` from local path** | **N/A** | `version` is **not allowed**; pin by Git tag on the repo, not `version` |
| **`module` from Git / S3 / HTTP** | **N/A** | Use `?ref=` (Git) or a fixed URL; no `version` argument |
| **`required_providers` `version`** | **No** — optional | Omit → `init` installs **latest** provider; **`.terraform.lock.hcl`** still pins after first init. **Strongly recommended** to set a constraint in config ([2a](../../02-fundamentals/02a-provider-versions)) |

**Best practice:** always **pin** registry modules (`version = "5.13.0"` or `~> 5.13`) and provider constraints in `required_providers`. Terraform **does not error** if you omit them — but unpinned registry modules and missing provider constraints make upgrades harder to control.

The `version` argument on a `module` block pins a module from a registry only.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = "demo"
  cidr = "10.0.0.0/16"
}
```

### Is `version` required?

**No** — for a **Terraform Registry** module (public or private), the `version` argument is **optional**. If you omit it, `terraform init` selects the **latest published version** of that module at init time and installs it under `.terraform/modules`.

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # no version → latest on init (today); a newer release can appear on a later init -upgrade
}
```

That is valid for the exam (“`version` is not required”). In real modules you still **pin** with `version = "5.13.0"` or `version = "~> 5.13"` so upgrades are deliberate and reviewable. Without a constraint, the next `terraform init -upgrade` (or init on a clean machine after a new registry release) can pull a newer major version and surprise you.

**Exam trap (false):** “When a `module` block references the Terraform Registry, the `version` attribute is **required**.” → **False.** `version` is **optional** on registry sources; omitting it uses the **latest** at `init`. **`version` is invalid** (not optional) on **local** and **Git** sources — there you must not use `version` at all; pin Git with `?ref=`.

`version` is allowed only when `source` is a registry module. A local path, a Git URL, and an S3 URL reject the argument. Git pins a version with `?ref=v1.2.0` on the source URL instead.

The version string uses the same constraint syntax as providers:

| Constraint | Meaning |
|---|---|
| `5.13.0` | exactly 5.13.0, the usual pin |
| `~> 5.13.0` | `>= 5.13.0` and `< 5.14.0` |
| `~> 5.13` | `>= 5.13.0` and `< 6.0.0` |
| `>= 5.0.0, < 6.0.0` | any 5.x |

An exact pin is the easiest to review. A pessimistic constraint lets you pick up patch releases with `terraform init -upgrade`.

`terraform init` selects the newest version that satisfies the constraint and records it under `.terraform/modules`. Unlike providers, module versions are not written to `.terraform.lock.hcl` in the same hash-locked way for every source. Registry module selection happens at init. Commit the configuration constraint. Re-run init when you change it.

## Providers inside a published module

A shared module declares `required_providers` with source and a minimum version, and it does not configure the caller-specific settings (account, region) unless those are its inputs. The root module owns `provider` blocks. The child says which plugins it needs. This is what makes one module usable in many accounts.

## Local modules have no version argument

This repo's pet module is local, so it has no `version`. You version it by versioning the Git repository that contains it. When you publish that directory to the registry, callers add `version`.

`versions.tf.example` in this folder shows the registry form. Terraform does not load `.example` files.
