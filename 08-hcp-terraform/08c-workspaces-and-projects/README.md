# 8c — Workspaces and projects

**New in 004.** Exam 003 did not have this objective. HashiCorp lists it as organizing and using HCP Terraform workspaces and projects. Index: [new-in-004.md](../../00-before-the-exam/new-in-004.md).

Docs: [Projects](https://developer.hashicorp.com/terraform/cloud-docs/projects), [organize workspaces with projects](https://developer.hashicorp.com/terraform/tutorials/cloud/projects), [run triggers](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings/run-triggers), [variable sets](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables/managing-variables), [connect workspaces tutorial](https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-run-triggers).

## One workspace, one state

An HCP Terraform workspace holds exactly one Terraform state. Put two unrelated lifecycles in one workspace and every plan shows both, every lock blocks both, and one bad apply is a large blast radius.

A practical split:

| Workspace | Owns |
|---|---|
| `network` | VPC, subnets, routing |
| `cluster` | Kubernetes control plane |
| `app-dev` | This application's dev stack |
| `app-prod` | The same configuration, different workspace, different variables |

The same repository can back several workspaces by setting a different Terraform working directory, a different variable set, or a different `cloud` workspace name. Same code, separate state. That is the hosted replacement for CLI `terraform workspace` when the environments need separate permissions.

## Projects

**Projects** let you **group related workspaces** in an HCP Terraform **organization** and manage them **collectively**. Every workspace belongs to **exactly one** project (new orgs start with a **Default Project**). Hierarchy from [8a](../08a-create-infrastructure): **Organization → Project → Workspace → Run**.

### Example layout

```text
HCP Terraform Organization
└── Project: "Production Infrastructure"
    ├── workspace: prod-networking
    ├── workspace: prod-compute
    └── workspace: prod-database

└── Project: "Development Infrastructure"
    ├── workspace: dev-networking
    ├── workspace: dev-compute
    └── workspace: dev-database
```

Each workspace still has **its own state**. The project is a **folder and governance boundary**, not a shared state file.

### What projects are for (exam)

| Goal | How the project helps |
|---|---|
| **Logical grouping** | Team, environment, or application — find related stacks together in the UI |
| **RBAC at scale** | Create an HCP **team** per squad; grant **Read / Plan / Write / Admin** on the **project** — access **inherits to every workspace** in that project ([8b — teams & scope](../08b-collaboration-governance#where-to-attach-permissions-scope)) |
| **Shared configuration** | Attach a **variable set** or **policy set** once at project scope — all workspaces in the project inherit it (unless a workspace overrides) |
| **Navigation** | Fewer flat lists of hundreds of workspaces; operate on “Production Infrastructure” as a unit |

You can also target workspaces in HCL with `cloud { workspaces { project = "platform" } }` when the CLI should be allowed to use any workspace in that project (see [8d](../08d-cli-integration)).

### What a project does **not** do

- **Does not merge state** — three workspaces in one project are still three separate states.
- **Does not replace workspaces** — you still split network / compute / database into separate workspaces when lifecycles differ.
- **Moving a workspace** between projects changes which **inherited** permissions, variable sets, and policy sets apply. It does **not** destroy infrastructure or rewrite state by itself.

## Variable precedence

**HCP “Terraform variable” vs environment variable, and `TF_VAR_*`:** [hcp-variables-and-tf-var.md](../hcp-variables-and-tf-var.md). Summary: UI type **Terraform variable** → `var.name`; **`TF_VAR_name`** as an **environment** variable also sets `var.name` but does **not** declare the variable in `.tf`.

When the same variable name is defined in more than one place, HCP Terraform uses the highest precedence value. Highest first:

1. Variables set on the workspace itself
2. Variable sets assigned directly to that workspace
3. Variable sets assigned to the workspace's project
4. Global variable sets, assigned to the whole organization

A workspace variable named `region` beats a project variable set's `region`. Use that when one workspace must deviate from the project default.

If several variable sets at the same level define the key, the set with the higher priority value wins. Terraform variables and environment variables are separate namespaces: a Terraform variable `region` and an environment variable `REGION` do not override each other.

`TF_VAR_name` as an **environment** variable in the workspace sets **`var.name`** only if `variable "name" { }` exists in the configuration — it does not create that block.

## Run triggers

A **run trigger** connects two workspaces. When the **source** workspace completes a **successful apply**, HCP Terraform queues a run (usually a **plan**) in the **downstream** workspace.

```text
network  --successful apply-->  (run trigger)  -->  compute queues a plan
```

### Where the trigger is configured

The trigger is **not** part of the `network` or `compute` stack code (no run trigger block next to `aws_subnet`). It is **workspace metadata**. Common options:

1. **UI** — on the **downstream** workspace: **Settings → Run triggers → Add** → source workspace `network`.
2. **Code (platform repo)** — the [`tfe`](https://registry.terraform.io/providers/hashicorp/tfe/latest/docs) provider in a separate bootstrap repo. Example in this folder: [run-trigger.tf.example](run-trigger.tf.example).

After `network` applies successfully, `compute` gets a new run automatically. Without a trigger, `compute` only plans when VCS, CLI, API, or a manual run starts it — even if `network` changed.

```hcl
# Platform repo only — hashicorp/tfe, not inside the compute root module.

data "tfe_workspace" "network" {
  name         = "network"
  organization = "example-org"
}

data "tfe_workspace" "compute" {
  name         = "compute"
  organization = "example-org"
}

resource "tfe_run_trigger" "network_to_compute" {
  workspace_id    = data.tfe_workspace.compute.id   # downstream
  sourceable_id   = data.tfe_workspace.network.id   # upstream (successful apply)
  sourceable_type = "tfe_workspace"
}
```

That resource is the API equivalent of the UI setting. It does **not** replace `terraform_remote_state` in the compute configuration; you still need both for “run after network changes” and “read network outputs.”

### Is `tfe_run_trigger` a “real” Terraform resource?

**Yes — but a platform resource, not cloud infrastructure.**

| | **`tfe_run_trigger`** | **`aws_s3_bucket` (example)** |
|---|---|---|
| **Provider** | `hashicorp/tfe` (Terraform Enterprise / HCP Terraform) | `hashicorp/aws` |
| **What it creates** | A **run-trigger link** between two **HCP workspaces** | An S3 bucket in AWS |
| **Predefined?** | Fixed schema from HashiCorp’s **tfe** provider — you do not define a custom resource type | Same — fixed `aws_s3_bucket` schema |
| **Lives in which repo?** | **Platform / bootstrap** Terraform that manages HCP objects | **App/infra** stack (`network`, `compute`) |

There is **no** `run_trigger` block in the Terraform language for your VPC module. Either you use the **UI**, the **API**, or **`resource "tfe_run_trigger"`** in a separate configuration that uses the **tfe** provider.

| Piece | Role |
|---|---|
| **Run trigger** (workspace setting on `compute`) | **When** to queue a downstream run after upstream apply |
| **`data.terraform_remote_state`** (in `compute`'s code) | **What** values to read from `network`'s state outputs during that plan |

### Reading upstream outputs in the downstream workspace

The downstream configuration reads the upstream outputs with `terraform_remote_state`:

```hcl
data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "example-org"
    workspaces = {
      name = "network"
    }
  }
}

locals {
  subnet_id = data.terraform_remote_state.network.outputs.subnet_id
}
```

The trigger does not copy state. It only queues a run so the downstream plan sees the new outputs. The team running the downstream workspace needs permission to read the upstream state.

Triggers are one direction. A cycle (A triggers B triggers A) is a design problem, not a feature. Keep the source as the workspace that produces shared data (network, DNS, a cluster), and the downstream as the workspace that consumes it.

## CLI workspaces are a different feature

`terraform workspace new prod` is a **CLI** feature (extra state files for the same `.tf`), covered in [6a](../../06-state/06a-local-backend). It is **not** an HCP Terraform workspace. Once this configuration uses the `cloud` block, you do not switch HCP environments with `terraform workspace select`. You bind or pick HCP workspaces with the `workspaces` block (`name`, `tags`, or `project`) or `TF_WORKSPACE` for CLI-driven runs. See [8d](../08d-cli-integration).

**Comparison (common vs different, `terraform.workspace` on HCP):** [cli-workspaces-vs-hcp-workspaces.md](../../06-state/cli-workspaces-vs-hcp-workspaces.md).
