# 8a — Create infrastructure with HCP Terraform

Docs: [Overview](https://developer.hashicorp.com/terraform/cloud-docs), [workspaces](https://developer.hashicorp.com/terraform/cloud-docs/workspaces), [remote operations](https://developer.hashicorp.com/terraform/cloud-docs/run/remote-operations), [get started collection](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started).

HCP Terraform stores the state for a workspace and, by default, runs `plan` and `apply` on its own workers. Your laptop (or your CI job) starts the run. The service executes it, saves the plan, and writes state.

## The objects

```text
Organization
  Project
    Workspace  = one state + variables + runs + settings
      Run      = one plan, then an optional apply
```

An **organization** is the account boundary: billing, teams, VCS connections, the private registry.

A **project** groups workspaces so permissions and variable sets can be granted once. Example org layout (prod vs dev projects): [8c — Projects](../08c-workspaces-and-projects#projects).

A **workspace** is one Terraform state. It points at a working directory (often a repo subdirectory), a Terraform version, variable values, and an execution mode. Two workspaces do not share state. That is how dev and prod stay apart.

A **run** is one execution: plan, policy check, then apply if the plan is confirmed and policies pass. Speculative plans (a pull request check) plan without applying.

## Three ways a run starts

| Workflow | What triggers the run |
|---|---|
| VCS-driven | A commit to the tracked branch, or a pull request for a speculative plan |
| CLI-driven | `terraform plan` / `terraform apply` after `terraform login` and a `cloud` block |
| API-driven | Your own system uploads a configuration tarball and creates a run via the API |

VCS-driven is the usual team setup: the repository is the source of configuration, and the workspace runs when that repository changes. CLI-driven is how you migrate a local directory and how a developer runs a one-off plan with local changes. API-driven is for pipelines that already know how to upload an artifact.

In all three, remote execution means the plan runs on HCP Terraform, using the workspace's Terraform version and variables, not whatever binary happens to be on your laptop. A local `local-exec` provisioner that reads a file on your laptop will not see that file during a remote run. The configuration uploaded with the run is what the worker has.

## Execution mode

| Mode | Plan and apply run… | State lives… |
|---|---|---|
| Remote | on HCP Terraform workers | in HCP Terraform |
| Agent | on an agent you host, in a private network | in HCP Terraform |
| Local | on your machine | in HCP Terraform |

Agent mode is for APIs the public workers cannot reach (a private datacenter). Local execution mode keeps state remote while the CLI does the work. The default you should assume in a question is remote execution.

## What a workspace stores for you

- State, with history, so you can inspect previous serials
- The Terraform version that workspace uses (you can upgrade it without everyone installing a new binary)
- Terraform variables and environment variables
- Cloud provider credentials (workspace env vars / dynamic `TFC_*` — not the `terraform login` token). Guide: [provider-credentials.md](../provider-credentials.md)
- Run history: who planned, what the diff was, whether policy passed

The open-source CLI plus an S3 backend gives you remote state (and locking if you configure it). It does **not** give you **state versions in the HCP UI**, **run history**, **remote execution**, **variable sets**, or **policy** on the plan. Checklist: [hcp-vs-open-source-cli.md](../hcp-vs-open-source-cli.md).

## A run, in order

1. Configuration is selected (VCS commit, CLI upload, or API upload).
2. The worker runs a plan, with the workspace variables.
3. Policy sets evaluate the plan. A hard-mandatory failure stops the run.
4. A human or an auto-apply setting confirms.
5. Apply runs, state is written, the lock is released.
6. Run triggers, if any, start runs in downstream workspaces.

Auto-apply skips the human confirm. It is a workspace setting. It is the hosted equivalent of `-auto-approve`, with the plan still saved and still subject to policy.
