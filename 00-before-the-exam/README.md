# Before the exam

| Resource | Role |
|---|---|
| [exam-curriculum.md](exam-curriculum.md) | Full 004 objective list with HashiCorp doc/tutorial links and repo folder links |
| [exam-objectives.md](exam-objectives.md) | Short map: objectives → folders in this repo |
| [new-in-004.md](new-in-004.md) | What 004 adds vs exam 003 (4f, 4g, 4h, HCP 8c) |

The Associate exam is closed book and multiple choice. You will not get a terminal. You will read a short statement or a snippet and pick the behavior Terraform actually has.

Question shapes, from the [sample questions](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-questions-004):

- True or false
- Multiple choice, one answer
- Multiple answer, the question says how many to pick ("Pick the 2 correct responses")

HashiCorp's own note on that page: the questions are not written to trick you. They test Terraform behavior, not spelling and not an obscure flag.

004 tests Terraform 1.12 and includes HCP Terraform. Compared with exam 003, HashiCorp adds four topics: 4f, 4g, 4h (ephemeral values and write-only arguments), and 8c. Those notes are indexed in [new-in-004.md](new-in-004.md).

Register from the [certification page](https://developer.hashicorp.com/certifications/terraform-associate).

## What "know it" means here

For each objective you should be able to:

1. Say what problem the feature solves.
2. Read a 15-line snippet and predict `plan` output (`+`, `-`, `~`, `-/+`, `+/-`).
3. Name the command that does the work, and the command people confuse it with.
4. Say what lands in state, and what is only redacted on screen.

Provider resource arguments (`instance_type`, `sku`, `machine_type`) are not the subject. If a question shows `aws_vpc`, it is asking about `var.vpc_cidrs["us-east-1"]` or about state, not about VPC design.

## Two products, one exam

**Terraform Community Edition** is the CLI: `terraform` binary, HCL, providers, a state file.

**HCP Terraform** is HashiCorp's hosted service. It stores state, runs plans remotely, holds variables and credentials, connects to a VCS, and adds teams, projects, policy, and drift detection. The CLI talks to it through `terraform login` and a `cloud` block.

A question that says "workspace" might mean either. Read the noun next to it:

- `terraform workspace select` and `terraform.workspace` are CLI workspaces (separate state files).
- "HCP Terraform workspace", "project", "organization", "run", "variable set", "policy set" are the hosted product.

## Setup on this machine

Terraform is already installed. The exam targets 1.12 behavior. A newer CLI still speaks that language.

```bash
terraform version
```

Editor settings that match `terraform fmt`: two-space indent, spaces rather than tabs.

```bash
cd labs/local-stack
terraform init
terraform apply
```

That lab is the place to make plan output boring before you read the later objectives. After it applies, the state commands in [07b](../07-maintain/07b-inspect-state) have something to inspect.

## Files in a working directory

```text
main.tf                 # resources; the filename is a convention, Terraform loads every .tf
variables.tf
outputs.tf
versions.tf             # terraform { required_version, required_providers }
providers.tf
terraform.tfvars        # auto-loaded variable values
.dev.auto.tfvars        # also auto-loaded
.terraform.lock.hcl     # commit this
.terraform/             # do not commit
terraform.tfstate       # do not commit
```

Terraform loads all `.tf` files in the directory as one module. Split files for humans. Names like `main.tf` are convention, not syntax.

## Order people mix up

| You want to… | Command |
|---|---|
| Download providers and modules | `terraform init` |
| Rewrite formatting | `terraform fmt` |
| Check that the configuration is internally valid | `terraform validate` |
| See the diff | `terraform plan` |
| Make the diff real and record it | `terraform apply` |
| Delete everything Terraform manages | `terraform destroy` |
| Adopt something that already exists | `resource` block **and** `import` / `import` block (both required) — [7a](../07-maintain/07a-import) |
| Update state to match outside changes, leave the cloud alone | `terraform apply -refresh-only` |
| Recreate one resource without editing `.tf` | `terraform apply -replace=ADDRESS` (`terraform taint` is gone) |

Which commands read `.tf`, call the cloud, and write state: [commands-config-infra-state](../03-core-workflow/commands-config-infra-state.md).

`apply` does not download plugins. `init` does not create infrastructure. `fmt` does not check types. `validate` does not call the cloud API. `plan` does not apply your configuration (it does refresh state).

## A correct mental model of a run

1. Load `.tf` files, variable values, and the backend.
2. Build a graph: nodes are resources, data sources, modules; edges are references and `depends_on`.
3. Refresh: read real objects and update state so the next diff is against reality.
4. Diff desired configuration against that refreshed state.
5. On apply, walk the graph, write state after each change, release the lock at the end.

State is the map from addresses (`random_pet.this`) to real IDs, plus the attribute values Terraform last saw. It is how Terraform knows what it manages. Edit it only through Terraform commands.

## Official sample, worked once

These are the public samples. The explanation is the part worth keeping.

**True.** Usernames and passwords written in configuration, including as variables, are stored in plaintext in state. `sensitive = true` hides them in CLI output. It does not encrypt the state file. Ephemeral values and write-only arguments are the later exception: those are omitted from state. The sample statement is still true for ordinary variables. Details in [04h](../04-configuration/04h-sensitive-data).

**`var.vpc_cidrs["us-east-1"]`.** Map keys are strings, so the index is a string. `var.` is required. `var.vpc_cidrs[0]` would be a list index. Details in [04d](../04-configuration/04d-complex-types).

**All of the above.** `terraform plan` loads `terraform.tfvars` automatically, and `-var-file=terraform.tfvars` also loads it. Details in [04c](../04-configuration/04c-variables-and-outputs).

**`plan` and `apply`.** Those two refresh state unless you disable refresh. `validate` checks configuration. `output` prints what is already in state. Details in [03d](../03-core-workflow/03d-plan).

**Apply makes the changes, and it updates state with what it changed.** Plugin download is `init`. Formatting is `fmt`. Apply updates in place or replaces individual resources; it does not rebuild the whole infrastructure on every run. Details in [03e](../03-core-workflow/03e-apply).
