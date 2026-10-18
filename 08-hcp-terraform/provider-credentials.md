# Cloud provider credentials on HCP Terraform

Companion for [8b](08b-collaboration-governance), [8a](08a-create-infrastructure), [8d](08d-cli-integration). Docs: [dynamic provider credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials), [AWS](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration), [Azure](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration), [GCP](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/gcp-configuration).

A remote run needs **two** different authentications. The exam often mixes them up.

| Credential | Who uses it | Where it lives | Purpose |
|---|---|---|---|
| **HCP / Terraform API token** | Terraform CLI ↔ HCP Terraform | `terraform login` → `credentials.tfrc.json` on your laptop | Upload config, stream logs, confirm apply, read remote state |
| **Cloud provider credentials** | AWS / Azure / GCP **provider** plugin during plan/apply | Depends on execution mode (below) | Call cloud APIs (`aws_instance`, `azurerm_*`, …) |

`terraform login` does **not** replace `AWS_ACCESS_KEY_ID` or dynamic AWS roles. The HCP token never becomes your cloud API key.

## Where the provider gets credentials (execution mode)

| Execution mode | Plan/apply runs on… | Cloud credentials must exist on… |
|---|---|---|
| **Remote** (default) | HCP Terraform workers | **Workspace** environment variables and/or **dynamic credentials** (OIDC → short-lived cloud token) |
| **Local** | Your laptop | **Your machine** (env vars, `~/.aws/credentials`, `gcloud auth`, …) — same as CLI-only Terraform |
| **Agent** | Your agent pool host | The **agent** (often same env-var patterns as remote workspace) |

**Exam trap:** With **remote** execution, your laptop’s `AWS_PROFILE` or `~/.aws/credentials` are **not** used for the run. Only what the **workspace** (or variable set) supplies counts, unless execution mode is **local**.

## Keep secrets out of `.tf` (still true on HCP)

Provider configuration in Git should usually set **region**, **features**, and **aliases** — not long-lived access keys.

```hcl
# provider-aws.tf.example — credentials come from the run environment, not from HCL.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

provider "aws" {
  region = var.aws_region
}
```

Putting `access_key` / `secret_key` in a `provider` block (or in a normal variable wired into the provider) is an anti-pattern and can land values in **state**. Prefer env vars or dynamic credentials. See [4h](../04-configuration/04h-sensitive-data).

## Option A — Dynamic provider credentials (preferred on HCP)

HCP Terraform presents an **OIDC workload identity** for the run. The cloud account trusts that identity and returns **short-lived** credentials. You configure **workspace environment variables** (or a variable set); nothing long-lived is stored in Git.

Cloud IAM must trust HCP (trust policy / federated identity / workload identity pool). That setup is account admin work; the exam tests **what Terraform expects in the workspace**, not the full IAM JSON.

### AWS (workspace environment variables)

```bash
# workspace-env-dynamic.aws.example — set in HCP UI: Workspace → Variables → Environment variables

TFC_AWS_PROVIDER_AUTH=true
TFC_AWS_RUN_ROLE_ARN=arn:aws:iam::123456789012:role/terraform-run
# Optional separate role for plan-only:
# TFC_AWS_PLAN_ROLE_ARN=arn:aws:iam::123456789012:role/terraform-plan
```

Provider block stays minimal (`region` only). The AWS provider picks up the temporary credentials injected for the run.

### Azure

```bash
TFC_AZURE_PROVIDER_AUTH=true
TFC_AZURE_RUN_CLIENT_ID=<app-registration-client-id>
TFC_AZURE_RUN_SUBSCRIPTION_ID=<subscription-guid>
TFC_AZURE_RUN_TENANT_ID=<tenant-guid>
```

```hcl
provider "azurerm" {
  features {}
  # No client_secret in HCL when using dynamic credentials.
}
```

### GCP

```bash
TFC_GCP_PROVIDER_AUTH=true
TFC_GCP_WORKLOAD_PROVIDER_NAME=projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL/providers/PROVIDER
TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL=terraform-run@PROJECT.iam.gserviceaccount.com
TFC_GCP_PROJECT_NUMBER=123456789012
```

```hcl
provider "google" {
  project = var.project_id
  region  = var.region
}
```

## Option B — Static keys as workspace environment variables

Still works: store **environment variables** on the workspace (mark **Sensitive** in the UI). Do **not** commit them to Git.

### AWS (static)

```bash
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
# Optional session token for assumed role:
# AWS_SESSION_TOKEN=...
AWS_DEFAULT_REGION=eu-west-1
```

### Azure (static)

```bash
ARM_CLIENT_ID=...
ARM_CLIENT_SECRET=...          # sensitive
ARM_SUBSCRIPTION_ID=...
ARM_TENANT_ID=...
```

### GCP (static)

Often `GOOGLE_CREDENTIALS` with the **JSON key file contents** as one env var (sensitive), or `GOOGLE_APPLICATION_CREDENTIALS` pointing at a path — on **remote** workers a file path usually fails unless you bake a custom image; JSON in `GOOGLE_CREDENTIALS` is the common remote pattern.

Dynamic credentials are preferred because keys do not sit in variable sets and rotate automatically per run.

## Option C — Local / laptop-only Terraform (no HCP remote execution)

Same providers, standard credential chain:

| Cloud | Common sources (no keys in `.tf`) |
|---|---|
| AWS | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`, shared config `~/.aws/credentials`, `AWS_PROFILE`, EC2 instance profile |
| Azure | `ARM_*` env vars, Azure CLI login |
| GCP | `GOOGLE_APPLICATION_CREDENTIALS`, `gcloud` application-default credentials |

`TF_VAR_*` sets **Terraform variables**, not the AWS provider env chain. Use `TF_VAR_` for app inputs (db name, instance size). Use **provider env vars** or **dynamic credentials** for **cloud API auth** unless you deliberately pass secrets into a `provider` block (avoid).

## Variable sets and precedence

Shared non-secret defaults (region, environment tag) belong in **variable sets** attached to a project or organization. **Credentials** can also be in variable sets, but scope them tightly (project/env), mark sensitive, and prefer **dynamic** credentials over copied keys.

Terraform variable vs environment variable in HCP:

| Kind in UI | Becomes | Example |
|---|---|---|
| **Terraform variable** | `var.name` in HCL | `instance_type`, `environment` |
| **Environment variable** | Process env for the run | `AWS_ACCESS_KEY_ID`, `TFC_AWS_PROVIDER_AUTH`, `TF_VAR_region` |

`TF_VAR_region` in the workspace environment sets **`var.region`** if `variable "region" { }` exists in code — it does not create the variable. Full guide: [hcp-variables-and-tf-var.md](hcp-variables-and-tf-var.md). Not a substitute for `TFC_AWS_*` dynamic auth.

## Quick exam checklist

- **`terraform login`** → HCP API token only.
- **Remote run** → cloud creds on the **worker** (workspace env / dynamic), not your laptop profile.
- **`cloud` block** → where **state** and **runs** live; it does **not** configure AWS.
- **Prefer dynamic credentials** over long-lived keys in workspace variables.
- **No access keys in committed `provider` blocks**; `sensitive` on a variable does not remove secrets from **state** if wired into resources.
- **Local execution mode** on the workspace → provider creds back on the machine running the CLI.

Example files in [08b-collaboration-governance](08b-collaboration-governance/): `provider-aws.tf.example`, `workspace-env-dynamic.aws.example`, `workspace-env-static.aws.example`.
