# Terraform vs other IaC and platform tools

**Not exam objectives.** This folder is for **breadth**: you learn Terraform deeply through the numbered curriculum (`01`–`08`), and you use these notes when you need **context** — how the same problems show up in Kubernetes, Crossplane, configuration management, and (over time) other ecosystems.

The Associate exam is one map of what matters. These comparisons are another: **platform design**, boundaries between tools, and where Terraform still wins, shares work, or should step back.

## Same IaC problems, different engines

Terraform and Crossplane (and Kubernetes GitOps) are all **declarative IaC**: describe desired state, let software close the gap. The **logical** concerns are the same; the **mechanisms** differ. Learning Terraform first is a strong reference frame — it is the **dominant** multi-cloud provisioning model in industry mindshare, and this repo’s `01`–`08` curriculum names the concerns explicitly.

| IaC concern (Terraform-shaped) | Crossplane-shaped answer | Note in this repo |
|---|---|---|
| Desired configuration | `.tf` / modules | CR YAML, Compositions | [overview](crossplane/crossplane-vs-terraform.md) |
| **Identity / binding** (“what did we create?”) | **State** + backend | **CR + etcd** + `.status` | [state & resilience](crossplane/crossplane-vs-terraform-state-and-resilience.md) |
| **Reuse / encapsulation** | **Modules** | **Composition + XRD + Claim** | [modules](crossplane/crossplane-vs-terraform-modules-and-compositions.md) |
| **Inputs / outputs** | `variable` / `output` | XRD schema / status / connection Secrets | [variables](crossplane/crossplane-vs-terraform-variables-and-inputs.md) |
| **Manage vs reference** | `resource` / `data` | MR vs EnvironmentConfig / refs / import | [resources & data](crossplane/crossplane-vs-terraform-resources-and-data.md) |
| **Secrets & sensitivity** | `sensitive`, ephemeral, write-only, env | K8s Secrets, ESO, ProviderConfig, identity | [secrets](crossplane/crossplane-vs-terraform-secrets-and-sensitive-data.md) |
| **Change review & DR** | `plan`, state versions, HCP runs | Git history, Velero/etcd, audit | [audit & DR](crossplane/crossplane-vs-terraform-audit-dr-and-recovery.md) |
| **Delivery / source of truth** | Git + CI / HCP VCS | Git + **Flux/Argo** (or CI apply) | [GitOps](crossplane/crossplane-vs-terraform-gitops-and-delivery.md) |
| **When reconciliation runs** | Batch **plan/apply** | Controller **loop** | [declarative K8s](declarative-terraform-and-kubernetes.md) |
| **Cloud API plug-in** | **Provider** plugin | **Provider** package + controllers | [overview — providers](crossplane/crossplane-vs-terraform.md) |

Neither tool invents new goals — **ownership, reuse, environments, secrets, audit, and drift** show up everywhere. Crossplane is “IaC with the Kubernetes control plane as the runtime.”

### Go as a shared implementation detail

**Terraform’s CLI/core** and **Kubernetes** are written in **Go**. Many **Terraform providers** and **Crossplane provider** controllers are Go as well (not required, but common). That is a useful **ecosystem** reference if you read source or debug controllers — it does **not** mean HCL and YAML are interchangeable; it means similar cultures (static binaries, client-go patterns, controller-runtime).

### Dominance — what that means here

**Terraform (and OpenTofu in the same workflow family)** is the default answer for **portable cloud infrastructure** in most platform teams. **Kubernetes** dominates **workload** orchestration. **Crossplane** is a **smaller** niche: cloud IaC **through** K8s, often beside Terraform rather than replacing it.

Using TF as the **spine** of this repo is intentional: master the logical points here, then map them to Crossplane (or Ansible, or cloud-native IaC) without relearning *why* state, modules, and plan matter.

## How to read this folder

| Track | Start here | Terraform topics to pair with it |
|---|---|---|
| **Kubernetes & GitOps** | [declarative-terraform-and-kubernetes.md](declarative-terraform-and-kubernetes.md) | [01a](../01-infrastructure-as-code/01a-what-is-iac), [03 workflow](../03-core-workflow), [08b health assessments](../08-hcp-terraform/08b-collaboration-governance/README.md) |
| **Configuration management** | [ansible/README.md](ansible/README.md) · [terraform-and-ansible.md](ansible/terraform-and-ansible.md) | [01a](../01-infrastructure-as-code/01a-what-is-iac), [04e provisioners](../04-configuration/04e-expressions-and-functions/local-provider-and-provisioners.md) |
| **PR-driven Terraform (GitOps-ish)** | [atlantis-and-hcp-terraform.md](atlantis-and-hcp-terraform.md) | [08 HCP vs CLI](../08-hcp-terraform/hcp-vs-open-source-cli.md), [06c backend](../06-state/06c-remote-backend/README.md) |
| **Crossplane (deep dive)** | [crossplane/README.md](crossplane/README.md) · [examples](crossplane/examples/README.md) | [02 providers](../02-fundamentals), [04c variables](../04-configuration/04c-variables-and-outputs/README.md), [06 state](../06-state), [08 HCP](../08-hcp-terraform/README.md) |

Example layout documented in [reference-platforms.md](../reference-platforms.md): **Terraform for cloud + cluster**, **GitOps in-cluster** for apps.

## Crossplane series

Multi-part comparison (overview + state + audit + variables):

| Note | Focus |
|---|---|
| [crossplane/crossplane-vs-terraform.md](crossplane/crossplane-vs-terraform.md) | Control loop, providers, Compositions, when to use which |
| [crossplane/crossplane-vs-terraform-state-and-resilience.md](crossplane/crossplane-vs-terraform-state-and-resilience.md) | etcd vs remote state, blast radius |
| [crossplane/crossplane-vs-terraform-audit-dr-and-recovery.md](crossplane/crossplane-vs-terraform-audit-dr-and-recovery.md) | Run history, rollback, DR drills |
| [crossplane/crossplane-vs-terraform-variables-and-inputs.md](crossplane/crossplane-vs-terraform-variables-and-inputs.md) | `variable` / HCP vs Claim / XRD / EnvironmentConfig |
| [crossplane/crossplane-vs-terraform-modules-and-compositions.md](crossplane/crossplane-vs-terraform-modules-and-compositions.md) | Modules vs Compositions and platform packages |
| [crossplane/crossplane-vs-terraform-resources-and-data.md](crossplane/crossplane-vs-terraform-resources-and-data.md) | `resource` / `data` vs MRs and cluster references |
| [crossplane/crossplane-vs-terraform-secrets-and-sensitive-data.md](crossplane/crossplane-vs-terraform-secrets-and-sensitive-data.md) | Sensitive, ephemeral, env vars vs Secrets / ESO / identity |
| [crossplane/crossplane-vs-terraform-gitops-and-delivery.md](crossplane/crossplane-vs-terraform-gitops-and-delivery.md) | Git-backed delivery with Crossplane |

## Planned expansions (stubs for now)

Ideas for future notes in this folder — same style, Terraform-centric:

| Topic | Angle |
|---|---|
| **Pulumi / CDK / OpenTofu** | Same declarative goal, different language or fork; state and workflow still Terraform-shaped for exam skills |
| **CloudFormation / Bicep / ARM** | Cloud-native IaC vs portable Terraform; import and drift stories |
| **Helm / Kustomize only** | In-cluster packaging vs Terraform Kubernetes provider — overlap with [declarative doc](declarative-terraform-and-kubernetes.md) |
| **OpenShift / Cluster API** | Cluster lifecycle next to `azurerm_kubernetes_cluster` / EKS modules |

Contributions welcome: [CONTRIBUTING.md](../CONTRIBUTING.md).

## Back to the curriculum

Exam-aligned IaC concepts only: [01 — Infrastructure as Code](../01-infrastructure-as-code/README.md).
