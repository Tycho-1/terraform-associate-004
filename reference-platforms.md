# Reference platforms

These three repositories are the same idea on three clouds: a Kubernetes platform written in Terraform, with internal modules, an environment root you actually `apply`, and GitOps after the cluster exists. The exam does not ask about EKS, GKE, or AKS. The platforms are where the exam's language shows up in real configuration.

The small examples in this study repo (`random`, `local`, `terraform_data`) teach the same mechanisms without a cloud account.

These repos intentionally use **Terraform for cloud + cluster** and **GitOps in-cluster** for apps — not Crossplane. Why TF vs Crossplane for platform design: [crossplane/crossplane-vs-terraform.md](terraform-vs-iac/crossplane/crossplane-vs-terraform.md).

| Platform | Where |
|---|---|
| AWS EKS | [github.com/Tycho-1/aws-eks-reference-platform](https://github.com/Tycho-1/aws-eks-reference-platform) |
| GCP GKE | [github.com/Tycho-1/gcp-gke-reference-platform](https://github.com/Tycho-1/gcp-gke-reference-platform) |
| Azure AKS | [github.com/Tycho-1/az-aks-reference-platform](https://github.com/Tycho-1/az-aks-reference-platform) |

## What is the same in all three

| Exam topic | In the platforms |
|---|---|
| [1a](01-infrastructure-as-code/01a-what-is-iac), [1b](01-infrastructure-as-code/01b-advantages) | The cluster, network, and add-on baseline are `.tf` files. A second apply with no diff changes nothing. |
| [1c](01-infrastructure-as-code/01c-multi-cloud) | One workflow (`init`, `plan`, `apply`) on AWS, GCP, and Azure. Each repo uses its own provider. None of them puts `aws`, `google`, and `azurerm` in a single configuration. |
| [2a](02-fundamentals/02a-provider-versions), [2b](02-fundamentals/02b-how-providers-work) | `required_providers` and a lock file. The root module owns the `provider` block. Child modules declare which plugins they need and do not set credentials. |
| [3](03-core-workflow) | You run Terraform from an environment directory, not from inside a module. GCP and AKS also run `fmt` and `validate` in CI. |
| [4c](04-configuration/04c-variables-and-outputs), [5](05-modules) | Environment-specific values are variables. Reusable pieces are modules. Callers read outputs, not resources inside the module. Registry modules are pinned and wrapped (`terraform-aws-modules/eks`, `terraform-google-modules`, Azure Verified Modules). |
| [8](08-hcp-terraform) | None of the three uses HCP Terraform. State is local (EKS), a GCS bucket (GKE), or an Azure storage account (AKS). Objective 8 is the hosted product those backends are not. |

## Where each repo is the example

**EKS** — [aws-eks-reference-platform](https://github.com/Tycho-1/aws-eks-reference-platform). Apply from `terraform/environments/cilium-karpenter` or `terraform/environments/default`.

- [2c](02-fundamentals/02c-multiple-providers). Two `provider "aws"` blocks. The second has `alias = "ecr"` and `region = "us-east-1"`, because ECR Public tokens are issued in that region. Several other providers (`helm`, `kubernetes`, `flux`) share the same state.
- [4f](04-configuration/04f-dependencies-and-lifecycle). `terraform/modules/rds-postgres` sets `create_before_destroy` on the database security group so a replacement exists before the old group is deleted.
- [5d](05-modules/05d-module-versions). The community EKS and VPC modules are called with a registry `source`. The internal modules (`eks-cilium-karpenter`, `eks-platform`, `rds-postgres`) are local paths.
- State stays on the machine that runs Terraform. There is no `backend` block. That is [6a](06-state/06a-local-backend), which the study notes treat as fine for a lab and a poor fit for a shared environment.

**GKE** — [gcp-gke-reference-platform](https://github.com/Tycho-1/gcp-gke-reference-platform). Apply from `terraform/environments/<env>/10-foundation`, then `20-platform`. Layout follows the [Google Cloud style guide](https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure) already linked from this study repo.

- [4g](04-configuration/04g-custom-conditions). `terraform/modules/gke-foundation/validations.tf` is a set of `check` blocks (open control plane, CIDR shape, node-pool names). The platform layer checks that a Flux deploy key or token is present. A failed check warns. It does not stop the run.
- [5](05-modules). `gke-foundation` is the reusable module. `dev` and `prod` are root modules that pass different sizing and deletion settings.
- [6c](06-state/06c-remote-backend). Each root has `backend "gcs"`. `terraform/bootstrap` creates the bucket. `terraform init -backend-config=...` supplies the bucket name, because a `backend` block cannot use variables.
- [6d](06-state/06d-drift-and-refactor) and [8c](08-hcp-terraform/08c-workspaces-and-projects). Foundation and platform are separate states so a cluster rebuild does not own the Flux install, and the other way around. That split is the same idea as two HCP Terraform workspaces, implemented with two GCS keys instead of HCP.

**AKS** — [az-aks-reference-platform](https://github.com/Tycho-1/az-aks-reference-platform). Apply from `environments/dev` or `environments/prod` after the state storage bootstrap.

- [2a](02-fundamentals/02a-provider-versions). `required_version = ">= 1.11"` so write-only arguments and ephemeral variables are available. The exam itself is Terraform 1.12.
- [4f](04-configuration/04f-dependencies-and-lifecycle). The AKS cluster uses `depends_on` for a role-assignment delay, `ignore_changes` for the node count the autoscaler owns, and `precondition` blocks for illegal input combinations (local accounts disabled with no admin group, authorized IPs on a private cluster).
- [4g](04-configuration/04g-custom-conditions). Module variables use `validation` blocks. `check "public_api_server_is_restricted"` warns when a public API server has no authorized ranges. That warning continues the run. A failed `precondition` stops it.
- [4h](04-configuration/04h-sensitive-data). `modules/postgresql-flexible-server` takes `administrator_password` as `sensitive` and `ephemeral`, and passes it to `administrator_password_wo`. `administrator_password_version` is the normal argument you increment to rotate it. The password is not stored in state.
- [6b](06-state/06b-locking), [6c](06-state/06c-remote-backend). `backend "azurerm" {}` is partial. The account and container come from `terraform init -backend-config=backend.hcl`. The storage account is the `storage-backend` module: versioned, locked down, no shared key.
- [8b](08-hcp-terraform/08b-collaboration-governance). CI plans on pull requests and applies on `main` with an OIDC identity (`bootstrap/github-actions-identity`). That is the same job dynamic provider credentials do on HCP Terraform, done here with GitHub Actions instead of a workspace variable.
