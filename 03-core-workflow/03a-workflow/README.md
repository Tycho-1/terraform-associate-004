# 3a — The Terraform workflow

Docs: [Core Terraform workflow](https://developer.hashicorp.com/terraform/intro/v1.12.x/core-workflow).

The workflow is the same for a local file and for a production network.

1. **Write** configuration: resources, variables, outputs, providers.
2. **Initialize** the working directory: `terraform init` downloads providers and modules and configures the backend.
3. **Plan**: `terraform plan` refreshes state and prints what would change.
4. **Apply**: `terraform apply` performs that change and writes state.

Around those, while you edit:

- `terraform fmt` rewrites style
- `terraform validate` checks that the configuration is internally consistent

Destroy is the same workflow pointed at deletion: `terraform destroy` plans the removal of every managed resource and then does it.

## What each step is allowed to change

| Step | Configuration | Real infrastructure | State |
|---|---|---|---|
| fmt | rewrites whitespace | no | no |
| init | writes lock file and `.terraform/` | no | no (it can migrate state if you asked) |
| validate | no | no | no |
| plan | no | no | yes, the refresh writes updated attributes |
| apply | no | yes | yes |
| destroy | no | deletes managed objects | removes them from state |

`plan` is the row people miss. It does not apply your configuration. It does update state with what refresh learned. A tag someone added in the console shows up as drift in the plan, and the refreshed value is stored.

## The graph

Terraform builds a dependency graph before it plans. An edge exists when one block references another, or when you set `depends_on`. Resources with no edge between them can be created in parallel. A cycle is an error.

`terraform graph` prints the graph in DOT. You rarely need the picture on the exam. You do need the consequence: order is computed, and you only write `depends_on` when no reference exists.

## A saved plan is a contract

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

`apply` of a saved plan file performs that plan and does not ask for confirmation. It also does not recompute the plan. This is what CI does: plan in one step, apply the artifact in the next, so the applied diff is the diff a human approved.

The plan file can contain sensitive values. Do not commit it.
