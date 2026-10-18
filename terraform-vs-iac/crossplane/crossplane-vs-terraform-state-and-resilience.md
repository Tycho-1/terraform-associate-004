# Crossplane vs Terraform — state, etcd, and resilience

Companion to [crossplane-vs-terraform.md](crossplane-vs-terraform.md). **Not on the Associate exam.** This note compares **where “memory of the world” lives**, what happens when that store fails, and the **security / blast-radius** tradeoff when **remote state** (for example S3) is separated from workload clusters.

Terraform state detail: [6c — remote backend](../../06-state/06c-remote-backend/README.md). HCP-hosted state: [8 — HCP Terraform](../../08-hcp-terraform/README.md).

---

## The comparison in one sentence

**Terraform** deliberately keeps **state outside** the infrastructure it manages (S3, GCS, Azure Blob, HCP workspace) so operations and disaster recovery can treat “the map of resources” as its own asset.

**Crossplane** keeps desired and observed cloud bindings **inside the Kubernetes API (etcd)** on the cluster that runs the controllers — so **cluster health and etcd durability are part of your platform DR story**, not a separate bucket.

Neither is automatically “more secure.” **Separation** (TF) vs **unification** (Crossplane) is a tradeoff.

---

## What is stored where

| | **Terraform** | **Crossplane** |
|---|---|---|
| **Desired config in Git** | `.tf` files | CR YAML (Claims, XRs, MRs) |
| **Runtime “who owns what ID”** | **`terraform.tfstate`** (JSON) | **CR `.spec` + `.status`** in etcd |
| **Physical store** | Backend you choose: **S3**, GCS, Azure, HCP, … | **etcd** (Kubernetes control plane) |
| **Typical distance from workloads** | State bucket often in **same cloud**, different service/account | Control plane often a **management cluster** (hopefully not the same as every app cluster) |

Terraform **state** and Crossplane **etcd** both can contain **sensitive attributes** (connection strings, IDs). Both need access control and encryption at rest. The difference is **which team and which blast radius** protects them.

---

## If the store is lost or corrupted

### Terraform — state in S3 (or similar)

**Scenario:** Laptop gone, CI runner wiped, but **S3 bucket** (with versioning) intact.

- **Recovery:** Point `terraform init` at the same backend; state is back. Continue `plan` / `apply`.
- **If state file is deleted but cloud resources exist:** Painful — `terraform import` or rebuild state; Git alone is not enough because `.tf` is not the binding map.
- **If bucket is gone without backup:** Same disaster class as losing etcd — you need **backups** (versioning, replication, cross-region) by design.

**Scenario:** Someone edits state or console-drifts resources.

- Next **plan** shows diff; you reconcile deliberately. State is the reconciliation anchor for **batch** runs.

S3 (and peers) gives **independent lifecycle**: you can backup, replicate, and IAM-lock a bucket **without** keeping the cluster that once ran `apply` online.

### Crossplane — records in etcd

**Scenario:** **Management cluster lost** (etcd gone, no restore).

- **CRs gone** — Crossplane no longer knows which cloud object matched which `Bucket` / `RDSInstance` CR unless you have **etcd backups** or **Git still has the manifests**.
- **Cloud resources may still exist** (orphans). Re-applying the same YAML from Git might **create duplicates** or **fail on name conflicts** unless external-name / import patterns are disciplined.
- Recovery is **restore etcd snapshot** and/or **careful re-adoption** of existing cloud IDs into new CRs — operational work, not a single `terraform init`.

**Scenario:** etcd healthy but **provider controllers down**.

- CRs remain; reconciliation pauses until controllers return. Cloud drift is not corrected until the loop runs again.

**Scenario:** Only **worker** cluster lost but **management** cluster (where Crossplane runs) is separate and backed up.

- Much better — this is the **recommended** architecture: Crossplane on a **dedicated management cluster**, not on the same etcd as customer workloads.

```text
Terraform (typical):
  Git (.tf)          S3 state (durable, IAM)          Cloud APIs
       \___________________|___________________________/
                    apply via CI / laptop

Crossplane (typical):
  Git (CR YAML)  →  mgmt cluster etcd  →  provider pods  →  Cloud APIs
                         ↑
                   backup / DR is YOUR etcd + Git story
```

---

## Security and separate remote state

Remote state in a dedicated bucket or account is often chosen for **separation of concerns**, not because the storage service alone guarantees security:

| Idea | **Remote TF state (e.g. S3)** | **Crossplane + etcd** |
|---|---|---|
| **Blast radius** | Compromise of an **app cluster** does not automatically expose **state** if state is in another account/bucket | Compromise of **management cluster** exposes **all CRs**, **ProviderConfigs**, and often **cloud credentials** for every attached account |
| **Access control** | **IAM** on bucket + optional KMS; narrow CI role | **Kubernetes RBAC** + who can read secrets / ProviderConfigs; cluster-admin is god |
| **Encryption at rest** | SSE-S3 / SSE-KMS on objects | etcd encryption at rest (cloud provider or KMS integration) — must be **enabled and operated** |
| **Audit** | S3 access logs, CloudTrail | K8s audit logs, who applied which CR |
| **Secrets in state** | State JSON can hold secrets in plaintext inside the blob — **encryption does not redact** | Same class of problem in CR fields and `status`; use external secret stores where possible |
| **Network exposure** | Bucket is an API endpoint; no cluster required to **read** state for planning | etcd is **not** meant for direct human access; everything goes through API server |

So: **S3 can be “more secure” in practice** when you put state in a **locked-down platform account**, restrict `terraform` roles, and **do not** run production control planes on the same failure domain as apps.

**Crossplane can be secure** when you treat the **management cluster** as tier-0: hardened, backed up, few admins, ProviderConfigs scoped, no shared cluster with untrusted tenants.

**Weak pattern:** Crossplane on the **same** cluster as arbitrary app workloads — then etcd blast radius resembles “state on the cluster you’re also hacking.”

---

## Durability features compared (operations checklist)

| Capability | **S3 / GCS / Azure state** | **etcd (Crossplane)** |
|---|---|---|
| Versioning / point-in-time | Bucket versioning, object lock (you configure) | etcd **snapshots** (vendor or Velero, etc.) |
| Geo redundancy | Cross-region replication (optional) | Multi-control-plane / hosted K8s SLA (EKS/GKE/AKS) — you still plan **restore** |
| Locking concurrent writers | S3+DynamoDB / native lock APIs / HCP lock | Kubernetes **resourceVersion** + single writer semantics on objects |
| Works if compute gone | **Yes** — state survives; new runner can plan | **Only if** etcd backup + restore or Git+reconcile strategy exists |
| Git as source of truth | **Partial** — `.tf` is intent; **state** is binding | **Stronger for intent** — CR YAML is intent; **status** is still runtime truth in etcd |

For Terraform, HashiCorp’s model assumes **remote state is a first-class product requirement**. For Crossplane, HashiCorp/kubernetes model assumes **the API server is the source of truth** and you **backup the control plane**.

---

## GitOps does not remove the problem

With **both** tools, **Git** should hold **desired** configuration.

| | After total loss of “memory” store |
|---|---|
| **Terraform** | Re-clone Git, restore **state from S3**, continue. Without state restore, recovery uses **import** or state rebuild. |
| **Crossplane** | Re-clone Git, **restore etcd** or re-apply CRs and **adopt** existing cloud resources. Without discipline (external names, tags, import tools), risk of **duplicate** infrastructure. |

Git is necessary; it is **not sufficient** for Terraform without state. For Crossplane, Git plus a healthy **or restored** control plane is the full story.

---

## When the “separate S3 state” angle favors Terraform

- Platform team is **not** standardized on a **dedicated, backed-up management cluster**.
- You want **state** in a **central security account** with IAM boundaries unrelated to any one K8s cluster.
- **Regulatory** or ops preference: infrastructure changes reviewed via **`plan`** artifacts stored next to state in CI.
- You manage **foundational** cloud (network, org policies) that must survive **any** cluster rebuild without re-import gymnastics.

## When etcd + Crossplane is acceptable or better

- You **already** operate tier-0 **management clusters** with etcd backup, DR drills, and strict RBAC.
- Self-service **Claims** and **namespace isolation** are the product; cloud objects are **downstream of CRs**.
- You want **continuous reconcile** and accept that **control plane availability** is part of platform SLO.

---

## Practical hybrid (common in industry)

```text
Terraform (S3/HCP state)  →  VPC, org, cluster, IAM baseline
        ↓
Management EKS/GKE/AKS    →  Crossplane installed; etcd backed up
        ↓
Optional app clusters     →  Flux/Argo; not the same etcd as mgmt
```

Terraform keeps **foundational** state in **S3**. Crossplane etcd holds **app-team-facing** CRs — but only if **mgmt cluster DR** is real, not hypothetical.

---

## Related notes

- [crossplane-vs-terraform-audit-dr-and-recovery.md](crossplane-vs-terraform-audit-dr-and-recovery.md) — **audit trail**, HCP state versions vs Velero/etcd, DR drill checklists
- [crossplane-vs-terraform.md](crossplane-vs-terraform.md) — reconciliation, providers, when to use which
- [06c — remote backend](../../06-state/06c-remote-backend/README.md) — encryption, locking, why migrate off laptop state
- [06b — locking](../../06-state/06b-locking/README.md)
- [08-hcp-terraform/hcp-vs-open-source-cli.md](../../08-hcp-terraform/hcp-vs-open-source-cli.md) — state versions and run history on HCP

**External:** [Kubernetes — etcd backup](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/), [Crossplane docs](https://docs.crossplane.io/), [Terraform state](https://developer.hashicorp.com/terraform/language/state).
