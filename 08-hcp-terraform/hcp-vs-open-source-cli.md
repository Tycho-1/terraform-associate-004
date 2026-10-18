# HCP Terraform vs open-source CLI (exam comparison)

**Open-source Terraform** = the `terraform` binary, HCL, providers, and a **backend** you choose (often **local** `terraform.tfstate` or **remote** `backend "s3"` / GCS / Azure).

**HCP Terraform** (and **Terraform Enterprise**) = HashiCorp’s **hosted platform** linked with **`terraform login`** and a **`cloud { }`** block. The **language and providers are the same**; the **service** adds collaboration and operations features.

HCP has its own **pricing tiers**. Exam questions usually mean: **“CLI + your backend”** vs **“HCP platform”**, not pricing — but know that a **Free plan exists**.

### Free tier (product fact, not core exam math)

HashiCorp’s current **[Free plan](https://developer.hashicorp.com/terraform/cloud-docs/overview)** is **$0** for up to **500 managed resources** (resources in HCP-managed state with `mode = managed`; null resources excluded), with **unlimited users** on that tier. It still includes many platform features teams care about: **remote execution**, VCS integration, **private module registry**, SSO, **policy enforcement**, run tasks, and more — subject to [plan limits](https://support.hashicorp.com/hc/en-us/articles/4414055267603-HCP-Terraform-Limits) (for example **one concurrent remote run** on Free). Paid **Essentials** and above bill per managed resource; see [pricing](https://www.hashicorp.com/pricing).

**Associate exam:** compare **capabilities** (run history, variable sets, remote ops) to **open-source CLI + S3** — not “is HCP free?” Limits change; use HashiCorp docs for interviews and real sign-up.

## What the exam often lists as HCP-only

| HCP offers | Open-source CLI + typical S3 backend |
|---|---|
| **State versions** — history of state snapshots in the workspace; inspect or roll back from the UI | One current state object in the bucket; versioning is **your** bucket lifecycle policy, not Terraform run UI |
| **Run history** — saved plans, who ran them, apply outcomes, policy results | No built-in run log; only your CI artifacts if you build that |
| **Remote execution** — plan/apply on HCP workers by default (`cloud` block) | Plan/apply on **whoever runs the CLI** (laptop, CI runner) |
| **Variable sets** — Terraform + **environment** variables attached to workspace, project, or org | `terraform.tfvars`, `TF_VAR_*`, CI secrets — **no** HCP variable sets |

Workspace-level variables (not only variable sets) also live on HCP; **variable sets** are how you **reuse** the same vars across many workspaces.

## Other common HCP additions (also fair on multi-select questions)

| Feature | CLI + S3 alone |
|---|---|
| Teams, **RBAC** (Read/Plan/Write/Admin) | No |
| **Policy** on plans (Sentinel / OPA) | No |
| VCS-driven runs, PR speculative plans | You wire GitHub Actions yourself |
| **Health assessments** (drift + `check` blocks on a schedule) | No |
| Private module/provider **registry** for the org | Public registry only unless you host one |
| **Run triggers** between workspaces | No |
| **Projects** — group workspaces; project-level RBAC, variable sets, policy | No — flat dirs/repos only |

## What open-source + remote backend **can** still give you

Without HCP, you can still have:

- **Remote state** and (on many backends) **locking** — e.g. S3 + DynamoDB or `use_lockfile`
- **Encryption at rest** on the bucket — you configure the cloud account
- **Same HCL** — nothing in `.tf` is “HCP-only syntax” for resources

You do **not** get HCP’s **run history**, **remote execution**, **variable sets UI**, **policy engine**, or **team permissions** from S3 alone.

## One-line answers

- **“State versions and run history”** → **HCP** (workspace), not plain CLI.
- **“Remote execution of Terraform operations”** → **`cloud` block** / HCP workspace (default), not `backend "s3"`.
- **“Store variables in variable sets”** → **HCP** org/project/workspace feature.

See [08a](08a-create-infrastructure), [08c — variable precedence](08c-workspaces-and-projects#variable-precedence), [cloud-block-rules — remote ops vs S3](08d-cli-integration/cloud-block-rules.md#cloud-vs-backend-s3--remote-state-vs-remote-operations).

**Beyond the exam:** self-hosted **PR plan/apply** with [Atlantis](../terraform-vs-iac/atlantis-and-hcp-terraform.md) vs HCP — same Git review idea, different ops model (`backend "s3"` + Atlantis vs `cloud { }`).
