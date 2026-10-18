# Crossplane examples — parallel to Terraform labs in this repo

These lessons mirror **how this repository teaches Terraform**: small, readable snippets and a short README per topic. They are **not** on the Associate exam.

**How to use them**

1. Open the **Terraform reference** path in the lesson README (same concept, runnable with `terraform init` / `apply` in this repo).
2. Read the **Crossplane YAML** in order (files are numbered).
3. Compare addresses: `aws_s3_bucket.logs` ↔ MR `Bucket` name; `module.pet` ↔ `Claim` + `Composition`.

**Running Crossplane YAML**

- Requires a **Kubernetes cluster** with **Crossplane** and a **provider package** installed (local **kind**, minikube, or a sandbox account).
- This repo does **not** CI-apply these files (no cluster in GitHub Actions). Treat them as **learning artifacts** — like reading `main.tf` before you run it.
- API versions (`upbound.io`, `crossplane.io`) change between releases; comments call out what to adjust for your version.

## Lesson map

| # | Crossplane lesson | Terraform concept in this repo |
|---|---|---|
| [01-managed-resource](01-managed-resource/README.md) | One cloud object (MR) | [4a resource](../../../04-configuration/04a-resources-and-data/README.md) — `resource` vs `data` |
| [02-provider-and-config](02-provider-and-config/README.md) | Provider package + `ProviderConfig` | [2c multiple providers](../../../02-fundamentals/02c-multiple-providers/README.md), `provider` block |
| [03-composition-and-claim](03-composition-and-claim/README.md) | XRD + Composition + Claim | [5c modules](../../../05-modules/05c-use-modules/README.md), [4c variables](../../../04-configuration/04c-variables-and-outputs/README.md) |
| [04-environment-config](04-environment-config/README.md) | Shared env constants | `data` + platform tfvars — [resources & data note](../crossplane-vs-terraform-resources-and-data.md) |
| [05-connection-secret](05-connection-secret/README.md) | Connection Secret (output) | [4h sensitive / outputs](../../../04-configuration/04h-sensitive-data/README.md) |
| [06-workflow](06-workflow/README.md) | `kubectl` apply/diff/wait | [3 — core workflow](../../../03-core-workflow/README.md) — init, plan, apply, destroy |

Concept notes (no separate YAML track): [state](../crossplane-vs-terraform-state-and-resilience.md), [GitOps](../crossplane-vs-terraform-gitops-and-delivery.md), [secrets](../crossplane-vs-terraform-secrets-and-sensitive-data.md).

## Optional: local cluster sketch

```bash
# Illustrative only — pin versions to what you use in production docs.
kind create cluster --name crossplane-learn
helm install crossplane crossplane/crossplane -n crossplane-system --create-namespace
# Install a provider package (see 02-provider-and-config), then kubectl apply -f 01-managed-resource/
```

## Series index

[Crossplane vs Terraform](../README.md) · [terraform-vs-iac hub](../../README.md)
