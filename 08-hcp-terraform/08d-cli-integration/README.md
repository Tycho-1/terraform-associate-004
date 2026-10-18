# 8d — CLI integration

Docs: [Use the CLI with HCP Terraform](https://developer.hashicorp.com/terraform/cli/cloud), [cloud settings](https://developer.hashicorp.com/terraform/cli/cloud/settings), [terraform login](https://developer.hashicorp.com/terraform/cli/commands/login), [migrate state](https://developer.hashicorp.com/terraform/cloud-docs/migrate), [migrate tutorial](https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-migrate).

The CLI-driven workflow is: log in, point the configuration at an organization and a workspace, init, then plan and apply as usual. The commands do not change. Where state is stored, and where the plan runs, does.

## Login

```bash
terraform login
```

The command opens a browser token flow for `app.terraform.io` and writes the token into the CLI credentials file on your machine (`credentials.tfrc.json` under the Terraform configuration directory). Later commands send that token. It is a user token. It is not something you commit, and it is **not** a cloud provider access key (AWS/Azure/GCP). Those are configured separately on the workspace for remote runs. See [provider-credentials.md](../provider-credentials.md).

`terraform login` with a hostname logs in to Terraform Enterprise or a different HCP Terraform region.

## The cloud block

```hcl
terraform {
  cloud {
    organization = "example-org"

    workspaces {
      name = "network"
    }
  }
}
```

`cloud` replaces the `backend` block. A configuration with both is invalid.

Full exam rules, invalid examples, and tags-based multi-workspace: **[cloud-block-rules.md](cloud-block-rules.md)**.

`workspaces` can be:

```hcl
workspaces {
  name = "network"
}
```

```hcl
workspaces {
  tags = ["app:billing", "env:prod"]
}
```

```hcl
workspaces {
  project = "platform"
}
```

A single `name` binds this directory to one workspace. Tags are how one configuration is used against several workspaces: you select the workspace at init or with `TF_WORKSPACE`. The tags in the block are a filter for which workspaces this configuration is allowed to use. Example: [cloud-tags.tf.example](cloud-tags.tf.example).

**Exam checklist:** at most **one** `cloud` block; **no** `backend` in the same configuration; at most **one** `backend` if you are not using `cloud`; multiple HCP workspaces = **one** `cloud` with `tags` or `project`, not two `cloud` blocks.

## Init migrates state

Add the `cloud` block to a directory that already has a local `terraform.tfstate` and run:

```bash
terraform login
terraform init
```

Init notices the backend change and offers to copy the local state into the HCP Terraform workspace. That is the same migration as `terraform init -migrate-state` for any other backend. After it succeeds, the workspace holds the state and a local apply is no longer writing `terraform.tfstate` as the source of truth.

If the workspace does not exist yet and your token is allowed to create it, init can create it. If the name is wrong, init fails rather than writing state somewhere new and silent.

## Plan and apply

```bash
terraform plan
terraform apply
```

With remote execution, the CLI uploads the configuration, the worker plans, and the CLI streams the output. Confirming apply confirms the remote run. The Terraform version is the workspace setting, which you can change in the UI or the API without installing that version locally. There is a tutorial for upgrading that version; the exam point is that the workspace pins the version the run uses.

`-auto-approve` is not how you skip policy. Policy sets still evaluate. A hard-mandatory failure stops the run on the service even if the CLI flag is present.

## Local execution mode

If the workspace execution mode is local, `plan` and `apply` run on your machine and the `cloud` integration only stores state and locks it. You still logged in. You still initialized. The process list on your laptop shows `terraform`, and **cloud provider** credentials need to exist **on that machine** (`AWS_*`, `ARM_*`, `gcloud`, …). In **remote** mode, workspace env vars and dynamic credentials on the worker matter; your local `AWS_PROFILE` does not. [provider-credentials.md](../provider-credentials.md).

## What not to confuse

| | CLI workspace | HCP Terraform workspace |
|---|---|---|
| Create | `terraform workspace new` | UI, API, or `cloud` block plus init |
| Select | `terraform workspace select` | `workspaces { name = ... }` or `TF_WORKSPACE` |
| Contains | a state file | state, variables, runs, permissions, version |
| With `cloud` configured | not used for env switching | this is the workspace |

Longer guide (what CLI workspaces are if you never used them, exam traps): [cli-workspaces-vs-hcp-workspaces.md](../../06-state/cli-workspaces-vs-hcp-workspaces.md).

`cloud.tf.example` in this folder is the block you add to a root module when you migrate [labs/local-stack](../../labs/local-stack) or any other root module.
