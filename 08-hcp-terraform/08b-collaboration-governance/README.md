# 8b — Collaboration and governance

Docs: [Teams](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/teams), [permissions](https://developer.hashicorp.com/terraform/cloud-docs/users-teams-organizations/permissions), [projects](https://developer.hashicorp.com/terraform/cloud-docs/projects), [policy](https://developer.hashicorp.com/terraform/cloud-docs/policy-enforcement), [health](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health), [private registry](https://developer.hashicorp.com/terraform/cloud-docs/registry), [explorer](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/explorer), [change requests](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/change-requests), [dynamic credentials](https://developer.hashicorp.com/terraform/cloud-docs/dynamic-provider-credentials).

Governance features sit on top of the run from [8a](../08a-create-infrastructure). They do not change HCL syntax. They change who can apply, whether the plan is allowed, and whether drift is noticed later.

## Teams and permissions

Users are members of an organization through teams. The **owners** team has full control and always exists. You grant access to other teams at the organization, on a project, or on a workspace.

Workspace permission sets you should recognize:

| Level | Typical ability |
|---|---|
| Read | See state, variables names, run history |
| Plan | Queue a speculative plan |
| Write | Plan and apply |
| Admin | Workspace settings, delete, manage variables and state |

Project access is inherited by the workspaces in that project, so a team granted write on a project can apply in every workspace the project contains. Organization-level permissions cover billing, team management, VCS connections, and the private registry.

A question about least privilege is answered by granting the lowest level that still lets the team do the job, on the smallest scope (one workspace, or one project, rather than the whole organization).

### Best practice: one HCP team per real-world team

Create **separate teams in HCP Terraform** for each team in your organization, then assign **project** and/or **workspace** permissions to each HCP team (users join teams; you rarely grant individuals workspace access one-by-one at scale).

**Why this is the usual best answer on the exam:**

- **Least privilege** — networking engineers get **Write** (plan + apply) only where they need it; compute teams do not inherit networking apply rights.
- **Blast radius** — users can only **apply** to workspaces their team is allowed to use; cross-team mistaken applies are **much less likely** (permissions + separate states still matter).
- **Efficiency** — grant once at **project** scope when every workspace in that project shares the same access pattern ([8c projects](../08c-workspaces-and-projects#projects)).

Example:

```text
HCP Terraform Organization
├── Team: "networking-team"
│   ├── permissions: Write on Project "Networking"     (plan + apply all workspaces in project)
│   └── permissions: Read on Project "Compute"         (view only)
│
└── Team: "compute-team"
    ├── permissions: Write on Project "Compute"
    └── permissions: (no access) on Project "Networking"
```

HCP permission names are **Read**, **Plan**, **Write**, **Admin** — exam prose “plan + apply” means **Write** (Plan alone cannot apply).

### Where to attach permissions (scope)

Teams can be granted access at **three scopes**. Narrower scope is preferred when access differs inside a project.

| Scope | What the grant covers |
|---|---|
| **Organization** | All workspaces in the org (and org-wide settings — use sparingly; **owners** team already has full control) |
| **Project** | **All workspaces** in that project — most efficient when a squad owns every stack in “Networking” or “Compute” |
| **Workspace** | **Single** workspace — when one environment in a project needs a different rule (e.g. prod read-only, dev Write) |

```text
Organization ──permissions──► every workspace
    └── Project ──permissions──► every workspace in project  ◄── common sweet spot
            └── Workspace ──permissions──► one state / one workspace
```

Organization-wide **Write** is almost never the least-privilege choice for product teams. Prefer **project-level** grants for a related set of workspaces, then **workspace-level** exceptions.

### RBAC (exam wording)

**True:** **HCP Terraform workspaces** support **role-based access control** — teams get **Read / Plan / Write / Admin** on a workspace, project, or organization. That is how you separate “can view prod state” from “can apply prod.”

**Not Kubernetes RBAC:** there are no `Role` / `RoleBinding` objects in your Terraform code. Access is configured in **HCP** (UI, API, or `tfe` provider), like SaaS IAM — not `kubectl auth can-i` on cluster APIs.

**Not CLI workspaces:** `terraform workspace select` only switches **which state file** is active. It grants **no** permissions. Exam trap: “workspaces offer RBAC” means **HCP** workspaces, not the CLI feature. Compare [cli-workspaces-vs-hcp-workspaces.md](../../06-state/cli-workspaces-vs-hcp-workspaces.md).

**Policy vs permissions:** **Permissions** control **who may run** plan/apply. **Policy** (Sentinel/OPA) controls whether a **given plan** is allowed — both can block a change, for different reasons.

## Variable sets

A variable set is a named group of Terraform variables and environment variables, applied to workspaces, to a project, or to the whole organization. Workspace-specific variables override variable sets. The full order is in [8c](../08c-workspaces-and-projects).

Use a variable set for values many workspaces share (a region, a default tag, an OIDC role). Use a workspace variable for a value that belongs to that one state (a unique name, a production-only flag).

## Cloud provider credentials

**Full guide with AWS / Azure / GCP examples:** [provider-credentials.md](../provider-credentials.md).

`terraform login` gives the CLI an **HCP API token**. That token does **not** authenticate the `aws`, `azurerm`, or `google` provider. During a **remote** run, cloud credentials come from **workspace environment variables** (and optional **variable sets**), not from your laptop’s `~/.aws/credentials`.

| Approach | Where you configure | Exam takeaway |
|---|---|---|
| **Dynamic provider credentials** (preferred) | Workspace **environment** vars (`TFC_AWS_*`, `TFC_AZURE_*`, `TFC_GCP_*`) | OIDC from HCP → short-lived cloud token; no long-lived key in Git |
| **Static keys** | Workspace env vars (`AWS_ACCESS_KEY_ID`, `ARM_CLIENT_SECRET`, …), mark **Sensitive** | Works but avoid; keys rot in variable sets |
| **Local execution mode** | Your machine’s env / CLI login | Same as non-HCP Terraform; remote worker env is ignored for the run |

Keep `provider` blocks free of access keys in committed `.tf`. Example HCL: [provider-aws.tf.example](provider-aws.tf.example). Workspace env sketches: [workspace-env-dynamic.aws.example](workspace-env-dynamic.aws.example), [workspace-env-static.aws.example](workspace-env-static.aws.example).

### Dynamic provider credentials (summary)

HCP Terraform presents a run **OIDC identity**. The cloud account trusts it and returns **short-lived** credentials. Configure the workspace with environment variables such as:

- **AWS:** `TFC_AWS_PROVIDER_AUTH=true`, `TFC_AWS_RUN_ROLE_ARN`
- **Azure:** `TFC_AZURE_PROVIDER_AUTH=true`, `TFC_AZURE_RUN_CLIENT_ID`, `TFC_AZURE_RUN_SUBSCRIPTION_ID`, `TFC_AZURE_RUN_TENANT_ID`
- **GCP:** `TFC_GCP_PROVIDER_AUTH=true`, `TFC_GCP_WORKLOAD_PROVIDER_NAME`, `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL`, `TFC_GCP_PROJECT_NUMBER`

`TF_VAR_*` sets **Terraform variables** (`var.region`), not the AWS credential chain. Use provider env vars or `TFC_*` dynamic auth for cloud API access.

## Policy

Policy as code evaluates a plan before apply. HCP Terraform runs **Sentinel** (HashiCorp's policy language) and **OPA** (Open Policy Agent, Rego). Policies are grouped into **policy sets** and attached to workspaces or projects.

Enforcement levels:

| Level | Plan that violates the policy |
|---|---|
| Advisory | The run records a warning and can continue |
| Soft-mandatory | The run stops, and a user with override permission can continue |
| Hard-mandatory | The run stops, and nobody overrides it |

Policy sees the **plan**, so a rule can inspect **planned** resource attributes before anything is created or updated in the cloud. A failed **hard-mandatory** policy means **apply never starts**.

**Example walkthrough:** Sentinel on **AWS S3** — deny runs unless buckets are **private** (public access block) and **server-side encryption** is enabled in the plan:

- Guide: [sentinel-s3-bucket-policy.md](sentinel-s3-bucket-policy.md)
- Compliant HCL: [s3-bucket-compliant.tf.example](s3-bucket-compliant.tf.example)
- Policy: [s3-private-and-encrypted.sentinel.example](s3-private-and-encrypted.sentinel.example)
- Policy set: [sentinel-policy-set.hcl.example](sentinel-policy-set.hcl.example)

```text
plan  →  Sentinel reads tfplan/v2  →  pass → confirm → apply
                          └── fail (hard-mandatory) → apply blocked
```

## Health assessments

A **health assessment** is a **background** process in HCP Terraform (formerly Terraform Cloud). It watches a workspace for **correctness** on a **schedule** — you do not have to queue a normal plan/apply run to get these results. Enable assessments on the workspace; findings show up as health alerts.

Assessments are built to catch two different problems:

| What it runs | What it finds | Typical examples |
|---|---|---|
| **Resource drift detection** | Real infrastructure no longer matches what Terraform last recorded in state (changes **outside** Terraform) | Someone edited a setting in the AWS Console; a tag was removed by another tool |
| **Continuous validation** (`check` blocks) | Your **functional** assertions fail when re-evaluated against live data | HTTP check returns non-200; certificate expiry is inside a warning window |

**Drift detection** refreshes state against the provider APIs and compares to the stored attributes. A difference is a drift finding. It does **not** change infrastructure and it does **not** write state. You reconcile later with a deliberate run (often `plan` / `apply`, or `apply -refresh-only` if you only need state updated).

**Continuous validation** re-executes the `check` blocks in your configuration (objective [4g](../../04-configuration/04g-custom-conditions)) on the health schedule — the same blocks that warn at the end of a local `plan` or `apply`. A failed assert is a health finding. That still does **not** block an apply that is already in progress; checks report. Locally, a failed check is a **warning**; in HCP Terraform it is also how ongoing monitoring surfaces.

**GitOps analogy:** Drift detection shares the GitOps idea of **desired vs actual**, but assessments **report**; they do not continuously **reconcile** like Flux or Argo CD. VCS-driven plan/apply (and optional auto-apply) is Terraform’s batch “apply from git”; health runs **between** those applies. Comparison: [declarative Terraform and Kubernetes](../../terraform-vs-iac/declarative-terraform-and-kubernetes.md).

Docs: [Workspace health](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/health).

## Private registry

The private registry hosts modules and providers for one organization. Workspaces fetch them during init on the remote worker. You use this when a module must not be public, or when you want a blessed set of modules teams are allowed to call. The source address points at the organization's registry host instead of `registry.terraform.io`.

## Explorer

Explorer queries resources across workspaces in the organization: every `aws_instance`, every workspace using a given module, filters on attributes. It reads the data HCP Terraform already has from state. It does not start a run.

## Change requests

A change request is a proposed infrastructure change that goes through review before it becomes a run that can apply. It is the governance wrapper around "someone wants to change this workspace," useful when the people who write configuration are not the people allowed to apply it.
