# 06 — Core workflow ≈ `init` → `validate` → `plan` → `apply` → `destroy`

## Terraform (this repo)

**Objective 3 — Core workflow:** [03-core-workflow/README.md](../../../../03-core-workflow/README.md)

Runnable lab:

```bash
cd 03-core-workflow/lab
terraform fmt
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform destroy
```

Concept tables: [03a — workflow](../../../../03-core-workflow/03a-workflow/README.md), [commands vs state](../../../../03-core-workflow/commands-config-infra-state.md).

## Crossplane idea

There is **no Terraform CLI** on the cluster. The **workflow** splits into:

1. **Bootstrap** (once per cluster) — install Crossplane + providers ≈ **`terraform init`**.
2. **Author** YAML in Git (often GitOps) — ≈ **write** `.tf`.
3. **Validate / preview** — API schema + **`kubectl diff`** ≈ **`validate` / `plan`** (weaker than `terraform plan`).
4. **`kubectl apply`** — writes **spec** to etcd ≈ **`apply`** (config only).
5. **Controllers reconcile** — cloud changes happen **after** apply, in a **loop** (no separate `apply` binary).
6. **`kubectl delete`** — CR gone → often cloud delete ≈ **`destroy`** for that object.

```text
Terraform (batch)     write .tf → init → validate → plan → apply → state + cloud

Crossplane (loop)     write YAML → bootstrap once → diff/dry-run → apply →
                      controller reconciles cloud continuously
```

## Command parallel (cheat sheet)

| Terraform | Crossplane / kubectl | Notes |
|---|---|---|
| `terraform fmt` | `yamlfmt`, `prettier`, editor | Style only |
| `terraform init` | `helm install crossplane` + `kubectl apply` **Provider** package | Downloads controllers + CRDs, not modules |
| `terraform validate` | `kubectl apply --dry-run=server` | Schema + admission; no cloud call |
| `terraform plan` | `kubectl diff -f ...` | **No saved plan file** by default; no full destroy preview like TF |
| `terraform plan -out` | *(no standard equivalent)* | GitOps PR comment / policy tools |
| `terraform apply` | `kubectl apply -f ...` | Updates **spec**; cloud catch-up is async |
| `terraform apply` (effects) | Watch **`.status.conditions`** (`Ready`, `Synced`) | Like waiting for apply to finish |
| `terraform destroy` | `kubectl delete -f ...` | Deletion policy / finalizers matter |
| `plan` refreshes state | Controller **observe** updates **`.status`** | Drift: TF next plan; CP reconcile loop |

Exam commands matrix ([commands-config-infra-state.md](../../../../03-core-workflow/commands-config-infra-state.md)) is **Terraform-only**. Crossplane does not have **state refresh** as a separate CLI step — **status** on the CR is the live view.

## Files in this lesson

1. [`01-bootstrap.sh.example`](01-bootstrap.sh.example) — annotated bootstrap ≈ `init` (kind + helm sketch).
2. [`02-validate-and-diff.sh.example`](02-validate-and-diff.sh.example) — `dry-run=server` + `kubectl diff` ≈ `validate` + `plan`.
3. [`03-bucket-workflow.yaml`](03-bucket-workflow.yaml) — same MR as lesson 01; edit `forProvider` to see reconcile.
4. [`04-watch-conditions.sh.example`](04-watch-conditions.sh.example) — wait for `Ready` ≈ “apply finished”.

## Walkthrough — change like a mini plan/apply

**1. Apply baseline** (after bootstrap + ProviderConfig from [lesson 02](../02-provider-and-config/README.md)):

```bash
kubectl apply -f 03-bucket-workflow.yaml
kubectl get bucket.example-workflow-logs -o yaml | grep -A5 conditions:
```

**2. Edit spec** (e.g. add a tag in `forProvider` per your provider schema) — same idea as editing `.tf`.

**3. Preview:**

```bash
kubectl diff -f 03-bucket-workflow.yaml
```

**4. Apply:**

```bash
kubectl apply -f 03-bucket-workflow.yaml
```

Controller updates AWS; watch conditions until `Ready=True`.

**5. Destroy exercise:**

```bash
kubectl delete -f 03-bucket-workflow.yaml
```

## What Terraform has that Crossplane does not (workflow)

| TF feature | Crossplane |
|---|---|
| Single **`plan`** output with create/update/destroy counts | `kubectl diff` + async reconcile; conditions for success/fail |
| **Saved plan** contract | PR review on Git diff; optional policy (OPA, composition functions) |
| **Graph** / explicit `depends_on` order | Order of MR creation inside Composition; K8s eventual consistency |
| **One-shot** apply then stop | **Continuous** reconcile until CR deleted |

## After this lesson

- **State / etcd:** [state & resilience note](../../crossplane-vs-terraform-state-and-resilience.md)
- **GitOps delivery:** [GitOps note](../../crossplane-vs-terraform-gitops-and-delivery.md)
- **Index:** [examples README](../README.md)
