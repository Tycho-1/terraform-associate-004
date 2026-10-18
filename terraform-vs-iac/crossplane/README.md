# Crossplane vs Terraform

Crossplane runs **cloud provisioning as Kubernetes controllers** (CRDs + reconcile loops). Terraform runs **batch plan/apply** with **remote state**. Both are declarative; the operational model differs.

Read in order for a full picture, or jump by concern:

| # | Note | Question it answers |
|---|---|---|
| 1 | [crossplane-vs-terraform.md](crossplane-vs-terraform.md) | What is each tool? Providers, reconciliation, Compositions, hybrid boundaries |
| 2 | [crossplane-vs-terraform-state-and-resilience.md](crossplane-vs-terraform-state-and-resilience.md) | etcd vs S3/HCP state — loss, security, blast radius |
| 3 | [crossplane-vs-terraform-audit-dr-and-recovery.md](crossplane-vs-terraform-audit-dr-and-recovery.md) | Audit trail, point-in-time recovery, DR drills |
| 4 | [crossplane-vs-terraform-variables-and-inputs.md](crossplane-vs-terraform-variables-and-inputs.md) | Inputs: `variable` / tfvars / HCP vs Claim / XRD / Composition |
| 5 | [crossplane-vs-terraform-modules-and-compositions.md](crossplane-vs-terraform-modules-and-compositions.md) | **`module`** vs **Composition / Claim / Configuration package** |
| 6 | [crossplane-vs-terraform-resources-and-data.md](crossplane-vs-terraform-resources-and-data.md) | **`resource` / `data`** vs **MR**, EnvironmentConfig, import |
| 7 | [crossplane-vs-terraform-secrets-and-sensitive-data.md](crossplane-vs-terraform-secrets-and-sensitive-data.md) | **`sensitive` / ephemeral / env** vs **Secrets, ESO, ProviderConfig, connection Secrets** |
| 8 | [crossplane-vs-terraform-gitops-and-delivery.md](crossplane-vs-terraform-gitops-and-delivery.md) | Is Flux/Argo **required**? Git as source of truth vs Crossplane reconcile loop |

**Hands-on YAML (parallel to TF labs):** [examples/README.md](examples/README.md) — MR through **workflow** (lessons 01–06).

**Prerequisites:** [Declarative Terraform and Kubernetes](../declarative-terraform-and-kubernetes.md) (shorter K8s + GitOps angle).

**Hub:** [terraform-vs-iac](../README.md).

**External:** [Crossplane documentation](https://docs.crossplane.io/).
