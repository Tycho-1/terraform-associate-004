# Atlantis, Terraform, and HCP Terraform

**Not exam objectives.** Exam comparison baseline: [hcp-vs-open-source-cli.md](../08-hcp-terraform/hcp-vs-open-source-cli.md). GitOps-shaped delivery for Terraform: [declarative-terraform-and-kubernetes.md](declarative-terraform-and-kubernetes.md), [Crossplane GitOps note](crossplane/crossplane-vs-terraform-gitops-and-delivery.md).

---

## What Atlantis is

**[Atlantis](https://www.runatlantis.io/)** is an **open-source, self-hosted** service that connects **Git pull requests** to **`terraform plan`** and **`terraform apply`**.

```text
Developer opens PR  →  VCS webhook  →  Atlantis server
                                              │
                                              ├─ terraform init / plan
                                              └─ posts plan output as PR comment

Reviewer approves + merge (or comment "atlantis apply")  →  Atlantis runs apply
```

| Piece | Role |
|---|---|
| **`.tf` in Git** | Source of truth (same as any TF workflow) |
| **Atlantis server** | Runs the **Terraform CLI** on a runner it controls (VM, K8s Pod, …) |
| **Backend** (`backend "s3"`, etc.) | **Unchanged** — state still in **your** bucket; Atlantis is not a backend |
| **`atlantis.yaml`** | Which directories are projects, autoplan, workflows, extra args |

Atlantis does **not** replace Terraform, providers, or remote state. It replaces **ad-hoc laptop apply** and much DIY **CI glue** for the **PR → plan → apply** loop.

---

## Is Atlantis “GitOps for Terraform”?

**Kind of — GitOps-flavored, not Kubernetes GitOps.**

| True GitOps (Flux/Argo) | Atlantis + Terraform |
|---|---|
| Desired state in Git; **controller continuously reconciles** cluster | Desired state in Git; **apply runs when you merge** (or comment apply) |
| Drift correction **in a loop** | Drift fixed on **next plan/apply** (unless you add drift jobs) |
| Kubernetes objects | Cloud/API resources via Terraform |

Atlantis is closer to **“Git-driven Terraform CI with PR comments”**:

- **Pull request** triggers **plan** (visibility before change).
- **Apply** is gated (merge, approval, `atlantis apply`, or policy you configure).
- **Git** remains authoritative for **configuration**; **state** still lives in the **backend** (or HCP if you pointed there — uncommon with Atlantis; see below).

For many teams that is **enough** to call it GitOps in conversation (“infra from Git with review”). Purists reserve “GitOps” for **continuous reconcile** controllers; Atlantis is **batch Terraform** with a **VCS-native UX**.

---

## Typical Atlantis flow (mental model)

1. Engineer changes `.tf` in a branch, opens PR.
2. Atlantis **autoplans** affected projects (per `atlantis.yaml`).
3. Plan output appears on the PR — reviewers see creates/updates/destroys.
4. After approval, someone runs **apply** (via merge + automerge config, or explicit `atlantis apply` comment — depends on your setup).
5. Atlantis runs `terraform apply`, state updates in S3 (or your backend).

**Locking:** Atlantis relies on Terraform’s **backend locking** (e.g. S3 + DynamoDB). It also serializes runs per project/repo so two PRs do not apply the same root module at once.

**Secrets:** Injected via env on the Atlantis runner, vault, or cloud identity — same problem class as CI; not HCP variable sets unless you integrate externally.

---

## Atlantis vs HCP Terraform

Both solve **“don’t run terraform on laptops in production”** and **“show plan on PR”**. Different ownership model.

| Dimension | **Atlantis** (self-hosted) | **HCP Terraform** (hosted) |
|---|---|---|
| **Who runs `plan`/`apply`** | **Your** Atlantis server / pods | **HashiCorp** remote workers (`cloud { }`) |
| **State storage** | **Your** backend (S3, GCS, …) typical | **HCP workspace** state (unless remote state sharing patterns) |
| **VCS integration** | Webhooks → Atlantis | Native VCS-driven runs, speculative plans |
| **PR plan comment** | Atlantis **signature feature** | HCP PR checks / UI run link |
| **Run history & state versions** | You build (CI logs, S3 versioning) | **Built-in** workspace UI |
| **RBAC** | VCS permissions + Atlantis repo config | **HCP teams** (Read/Plan/Write/Admin) |
| **Policy on plan** | Bring your own (OPA in CI, etc.) | **Sentinel / policy sets** (paid tiers) |
| **Variable sets / UI vars** | Env on runner, `tfvars` in repo | **HCP variable sets** |
| **Drift detection** | Custom (cron plan, tools) | **Health assessments** (HCP) |
| **Ops burden** | Patch Atlantis, scale runners, secure tokens | HashiCorp SaaS; limits per plan |
| **Cost** | Infra + engineer time | Free tier / per-resource pricing |
| **Exam angle** | Still **open-source CLI + backend** story | **`cloud` block**, remote execution, state versions |

**Common pattern:** Teams on **S3 + Atlantis** want **HCP-like collaboration** without the **HCP bill** or without sending state to HashiCorp. Teams on **HCP** want **less** to operate and **integrated** governance.

**Mixing:** Usually **either** default workflow per repo — `cloud { }` **or** `backend "s3"` + Atlantis, not both on the same root module ([cloud vs backend](../08-hcp-terraform/08d-cli-integration/cloud-block-rules.md)). Atlantis is aimed at **CLI + self-managed backend**.

---

## When Atlantis is a good fit

- Already **self-hosting** (K8s, VMs); comfortable operating a small service.
- **Multi-repo** infra with one PR comment UX across them.
- Want **plan on PR** without adopting **full HCP** or writing **GitHub Actions** from scratch.
- **State must stay** in your cloud account (S3) with your IAM boundaries.
- Team likes **explicit `atlantis apply`** (or merge-to-apply) — batch change windows.

## When HCP is a better fit

- Want **hosted** runs, **state versions**, **run history**, **workspace RBAC** without building them.
- **Policy on plans**, **run tasks**, **health assessments**, **private registry** as a package.
- Prefer **not** running Atlantis pods, VCS webhook secrets, and runner scaling yourself.
- Exam prep / employer standardizes on **`cloud { }`**.

## When neither — plain CI

GitHub Actions / GitLab CI running `terraform plan` on PR and `apply` on main is the same **idea** as Atlantis with **more YAML you own** and **no** centralized PR comment bot unless you add it.

---

## Relation to a typical platform layout

| Layer | Tool |
|---|---|
| **Cloud + cluster** (VPC, AKS, IAM) | Terraform — Atlantis **or** HCP **or** CI |
| **In-cluster apps** | Flux / Argo (true continuous GitOps) |
| **Optional Crossplane** | GitOps for CRs + Crossplane loop ([note](crossplane/crossplane-vs-terraform-gitops-and-delivery.md)) |

Atlantis does **not** replace Flux/Argo; it **Terraform-izes** the **infra repo** delivery story.

---

## One-line summaries

- **Atlantis** = self-hosted **PR-driven `plan`/`apply`** for Terraform; **GitOps-ish**, not a reconcile loop.
- **HCP Terraform** = **hosted** runs, state, collaboration, and governance on top of the **same** HCL.
- **Exam:** Atlantis is **not** a HashiCorp product — know it as **community automation** around the **open-source CLI + backend**, contrasted with **`cloud { }`** features in [hcp-vs-open-source-cli.md](../08-hcp-terraform/hcp-vs-open-source-cli.md).

**External:** [Run Atlantis docs](https://www.runatlantis.io/docs/), [HCP Terraform VCS workflows](https://developer.hashicorp.com/terraform/cloud-docs/run/ui).
