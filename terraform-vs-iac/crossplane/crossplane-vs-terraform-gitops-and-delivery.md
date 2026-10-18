# Crossplane — do you need GitOps (Flux / Argo CD)?

Eighth note in the Crossplane series. **Not exam content.** Pairs with [declarative Terraform and Kubernetes](../declarative-terraform-and-kubernetes.md) and [reference platforms](../../reference-platforms.md) (Terraform + cluster, **GitOps inside** for apps).

---

## Short answer

| Statement | Verdict |
|---|---|
| Crossplane **requires** Flux or Argo CD | **No** — not a technical dependency |
| Crossplane **without** Git-backed delivery is **uncommon in production** platforms | **Typical** teams still use Git + automated apply (Flux, Argo, or CI) |
| Flux/Argo are the **only** way to do GitOps | **No** — CI that applies manifests from Git after merge is the same **idea** |

**Technical fact:** Crossplane reconciles from the API even when manifests are applied only with `kubectl`. **Operational norm:** production platforms usually pair it with **Git as source of truth** and **automated apply**, so Compositions, Claims, and promotions stay reviewable and recoverable — the same maturity expectation as Terraform with version control rather than laptop-only apply.

Layer 2 (Crossplane) does not replace layer 1 (delivery). Without layer 1, desired state often lives in ad-hoc edits or external runbooks instead of version control.

---

## Two different loops (do not conflate them)

```text
Layer 1 — DELIVERY (optional tool: Flux / Argo / CI)
  Git commit  →  apply to API server  →  CR .spec updated

Layer 2 — CROSSPLANE (always on, once installed)
  CR .spec  →  provider controller  →  cloud API  →  .status
```

**Crossplane** is **layer 2**: continuous reconcile from **whatever** is in the Kubernetes API.

**GitOps** is **layer 1**: keep cluster objects (including Claims, Compositions, ProviderConfigs) aligned with **Git**, with PR review and automated sync.

Without layer 1, layer 2 still runs — but desired state may come from **ad-hoc `kubectl`**, a **portal**, or **CI one-off applies**. You lose the usual platform guarantees unless you replace them another way.

---

## How people run Crossplane without Flux/Argo

| Pattern | When it appears |
|---|---|
| **`kubectl apply` / CI `kubectl`** | Early PoC, break-glass, small teams |
| **Pipeline applies YAML** on merge (no Flux CRD) | “GitOps philosophy” without Argo/Flux installed |
| **Internal portal / Backstage** creates Claims via API | Self-service; Git may only hold templates |
| **Terraform `kubernetes_manifest`** (or Helm) | Installs Crossplane **packages**; TF owns that slice of API |
| **Cluster API / managed add-ons** | Bootstrap only |

All of these can work. **Production** teams usually add **Git-backed delivery** because operations questions get hard otherwise: *who changed this Claim, can we revert, can we promote dev → prod, what if the cluster is empty but Git is fine?*

---

## Why Crossplane + GitOps is such a common pairing

| Need | What GitOps adds | What Crossplane alone gives you |
|---|---|---|
| **Review before change** | PR diff on YAML | Only if humans review before apply somewhere |
| **Audit trail** | Git history | K8s audit log (who patched API), not always friendly |
| **Disaster recovery** | Re-apply from Git | Re-apply **if** Git was complete (Compositions, XRDs, Claims) |
| **Drift of manifests** | Flux/Argo re-sync spec in cluster | Crossplane fixes **cloud** drift vs CR spec — not “someone edited CR in cluster” unless you forbid direct edits |
| **Multi-cluster** | Same repo, overlays per cluster | Same Compositions; delivery tool targets each cluster |

[Reference platforms](../../reference-platforms.md) in this repo use **Terraform** for cluster and cloud and **Flux/Argo** for in-cluster workloads. Crossplane **Claims** and platform CRs would follow the same GitOps path — not a second writer on the same cloud objects as Terraform.

---

## What must be in Git (typical platform split)

| In Git (platform repo) | Often **not** in Git (secrets / runtime) |
|---|---|
| XRDs, Compositions, ProviderConfigs (refs only) | Secret **values** — ESO, Sealed Secrets, SOPS |
| Flux/Argo bootstrap | Cloud credentials (IRSA / WI) |
| App-team **Claim** manifests (or Kustomize per env) | Connection Secrets **written by provider** |

Crossplane without GitOps does not remove the need for **somewhere** to define Compositions — only moves it to **imperative** installs (harder to review).

---

## Comparison to Terraform GitOps

| | **Terraform GitOps** | **Crossplane + GitOps** |
|---|---|---|
| **Source of truth** | `.tf` in Git | CR YAML in Git |
| **Apply engine** | `terraform plan/apply` in CI or HCP | Flux/Argo **or** CI → API server |
| **Reconcile cloud** | On apply (batch) | Crossplane controllers (loop) |
| **“Can I skip Git?”** | Possible; painful at scale | Possible; painful at scale |

Terraform **does not require** GitOps either — but mature teams use VCS + pipeline. Same maturity curve for Crossplane manifests.

---

## When “no GitOps” is still defensible

Narrow cases only:

- **Sandbox / learning** — prove a provider MR works; `kubectl` is enough.
- **CI applies from Git on merge** but you **choose not** to install Flux/Argo — still GitOps in practice.
- **Bootstrap** before GitOps is wired (hours/days), not the steady state.

Everything else (portal-only, permanent `kubectl` ops, “we’ll document it in Confluence”) tends to rot. If **app teams** create Claims, **Git-backed delivery** is how self-service stays auditable.

---

## Practical rule of thumb

```text
Crossplane alone  =  reconciler engine (layer 2)

Delivery layer    =  Git + PRs + Flux/Argo OR CI-apply-from-Git  (layer 1)

Typical production =  both layers
```

Flux and Argo CD are **not** mandatory binaries — **version-controlled manifests + automated apply** is what production teams usually implement; sandboxes may omit layer 1 while learning the reconcile loop.

---

## Related notes

- [crossplane-vs-terraform.md](crossplane-vs-terraform.md) — GitOps table under reconciliation  
- [declarative-terraform-and-kubernetes.md](../declarative-terraform-and-kubernetes.md)  
- [crossplane-vs-terraform-secrets-and-sensitive-data.md](crossplane-vs-terraform-secrets-and-sensitive-data.md) — what not to commit  
- [crossplane-vs-terraform-audit-dr-and-recovery.md](crossplane-vs-terraform-audit-dr-and-recovery.md) — Git + etcd in DR  

**External:** [Flux](https://fluxcd.io/), [Argo CD](https://argo-cd.readthedocs.io/).
