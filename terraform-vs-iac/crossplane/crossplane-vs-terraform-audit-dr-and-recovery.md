# Crossplane vs Terraform — audit, DR drills, and recovery playbooks

Third companion in the Crossplane series:

1. [crossplane-vs-terraform.md](crossplane-vs-terraform.md) — models, reconciliation, when to use which  
2. [crossplane-vs-terraform-state-and-resilience.md](crossplane-vs-terraform-state-and-resilience.md) — **where** state lives, blast radius  
3. **This note** — **who changed what**, **point-in-time recovery**, and **what to rehearse** before a real outage  

**Not on the Associate exam.** HCP comparison detail: [hcp-vs-open-source-cli.md](../../08-hcp-terraform/hcp-vs-open-source-cli.md).

---

## Why a third angle matters

Doc 2 asks: *if etcd or the state bucket disappears, what breaks?*

This doc asks:

- Can you **prove** who promoted a change and what the world looked like **before** it?
- Can you **restore** to yesterday without guessing imports?
- Have you **tested** that restore, or only enabled versioning on paper?

Separation of state (Terraform) vs control-plane storage (Crossplane) does not replace **operational evidence** and **rehearsed recovery**.

---

## Change evidence — what you get “for free”

| Evidence | **Terraform (CLI + S3)** | **Terraform (HCP Terraform)** | **Crossplane on Kubernetes** |
|---|---|---|---|
| **Desired config history** | Git commits on `.tf` | Git + VCS-driven runs | Git on CR YAML + GitOps PRs |
| **Binding map history** | S3 **object versions** (if you turned versioning on) | **State versions** per workspace (UI/API) | **etcd** snapshots; CR `resourceVersion` is not a full timeline |
| **Plan before apply** | CI artifact if you save `plan` output / binary | **Run history** — saved plan, policy results | `kubectl diff` / PR checks; not one global “plan store” unless you build it |
| **Who applied** | CI job identity / IAM role in CloudTrail | HCP **user/team** on the run | K8s **audit log** — user/SA that patched the CR |
| **Drift detection** | Next `plan`, HCP **health assessments** (if on HCP) | Scheduled assessments + notifications | Controller **conditions** + optional drift tools; continuous reconcile |
| **Rollback story** | Restore **older state version** + `plan` (careful: may not undo cloud) | UI **state rollback** + targeted apply | Restore **etcd/Velero** or revert Git + reconcile (may not delete cloud orphans) |

**Takeaway:** HCP gives a **packaged audit trail** around runs and state. S3-only Terraform gives **strong storage** if you version objects and log IAM — but **you** assemble the narrative in CI. Crossplane’s native story is **Kubernetes audit + GitOps**; etcd backup is the analog of state versioning, not a substitute for PR history.

---

## Point-in-time recovery — realistic paths

These are **platform** actions, not product buttons (except HCP state versions).

### Terraform — self-managed S3 backend

| Goal | Typical path |
|---|---|
| **Recover after bad apply** | Restore **previous S3 object version** of `terraform.tfstate` → `terraform plan` → fix forward or `apply` to align cloud |
| **Recover after state delete** | S3 versioning / replication → restore object; if bucket gone, secondary region copy |
| **Recover when cloud was changed outside TF** | Current state + `plan` shows drift; **do not** roll state back blindly without understanding cloud |
| **Prove pre-change state** | S3 version ID + timestamp; optional `terraform state pull` archived in CI per run |

Locking (DynamoDB / `use_lockfile`): protects **concurrent writes**, not **logical** rollback — still need versioning.

### Terraform — HCP Terraform

| Goal | Typical path |
|---|---|
| **Inspect history** | Workspace → **States** / run list |
| **Rollback binding map** | **State version** restore in UI → new run to reconcile |
| **Prove who ran what** | Run record (user, VCS commit, policy outcome) |

State rollback **does not automatically revert cloud resources** — it changes what Terraform *believes*; the next plan/apply may propose destroys or updates. Same discipline as S3 version restore.

### Crossplane — management cluster

| Goal | Typical path |
|---|---|
| **Recover CRs + status** | **etcd snapshot** restore (managed K8s backup product or self-managed etcd) |
| **Recover namespaced resources + CRDs** | **Velero** (or cloud backup) including CRDs, Crossplane packages, secrets — test restores in a sandbox cluster |
| **Recover when only Git remains** | Re-install Crossplane → re-apply manifests → **adopt** existing cloud IDs (`crossplane.io/external-name`, provider import patterns, or delete orphans by policy) |
| **Prove who changed a bucket** | API audit: `kubectl` user/SA + optional GitOps commit; cloud CloudTrail for the actual API call |

Velero backs up **Kubernetes objects** (including CRs). It is **not** a replacement for **cloud-level** backup (RDS snapshots, S3 replication). You need **both** layers for tier-0 data services.

```text
                    POINT-IN-TIME ANCHORS

Terraform (S3)     object version N-1  ──►  state file  ──►  plan
Terraform (HCP)    state version N-1   ──►  workspace   ──►  run
Crossplane         etcd snap / Velero  ──►  CR+status   ──►  reconcile
                   Git commit          ──►  spec only   ──►  may duplicate cloud
```

---

## RPO / RTO — rough expectations (you define the numbers)

| | **Terraform + versioned remote state** | **Crossplane + backed-up mgmt cluster** |
|---|---|---|
| **RPO** (how much binding history you can lose) | Time between S3 versions or HCP state snapshots — can be **minutes** if every apply versions state | Time between etcd/Velero schedules — often **hours** unless frequent |
| **RTO** (how long until you can plan/reconcile again) | New runner + `init` + restored state — often **tens of minutes** if bucket healthy | New/rebuilt cluster + restore snapshot + provider pods healthy — often **hours** unless automated |
| **Human skill** | Understand state vs cloud mismatch after rollback | Understand CR adoption, external names, orphaned cloud |

Publish **your** RPO/RTO in a platform doc; the table above is order-of-magnitude, not a SLA.

---

## DR drill checklist (platform runbook)

Run these in a **non-prod** account or cluster at least once per year.

### Terraform track

- [ ] Confirm **versioning** (and optional replication) on the state bucket; deny `s3:DeleteObject` without MFA for prod roles where possible  
- [ ] From CI, archive **`terraform plan`** (and optional `plan -out`) per production apply  
- [ ] Drill: delete **current** state object (in sandbox) → restore **previous version** → `plan` matches expectation  
- [ ] Drill: simulate **wrong apply** → restore state version → document whether cloud rollback is manual  
- [ ] If HCP: drill **state version** restore and read **run history** for the incident narrative  

See [06c — remote backend](../../06-state/06c-remote-backend/README.md), [06b — locking](../../06-state/06b-locking/README.md).

### Crossplane track

- [ ] **Management cluster** is separate from app clusters; backup scope documented  
- [ ] etcd / **Velero** restore tested into an empty cluster; Crossplane providers reach cloud  
- [ ] GitOps repo is **complete** for Compositions, XRDs, ProviderConfigs (not only Claims)  
- [ ] Naming/tags/**external-name** policy so re-apply does not duplicate S3 buckets or RDS instances  
- [ ] Drill: delete a CR in etcd (sandbox) while cloud object remains → document adopt vs delete procedure  
- [ ] K8s **audit logs** retained long enough for security/compliance questions  

---

## Audit and compliance angles (neither tool solves alone)

| Question | Terraform leaning answer | Crossplane leaning answer |
|---|---|---|
| **Separation of duties** | HCP **teams** (plan-only vs apply); CI OIDC role per env | **RBAC** — who can create Claims vs cluster-scoped XRs |
| **Immutable audit log** | S3 Object Lock / Glacier + CI logs; HCP run retention | WORM storage for audit logs; SIEM export |
| **Change approval** | PR + required `plan` comment; Sentinel/OPA on HCP | PR + policy (Kyverno/Gatekeeper) + optional manual sync |
| **Secrets in audit trail** | `plan` and state can leak secrets — **sensitive** flags, redacted CI | CR `status` and events — scrub logs; use external secrets |

For exams and interviews: **remote state** and **etcd** both hold sensitive data; audit is about **process + retention + access control**, not which store is “cleaner.”

---

## How the three docs fit together

| Doc | Question |
|---|---|
| [crossplane-vs-terraform.md](crossplane-vs-terraform.md) | Same problem, different control loop? |
| [state-and-resilience](crossplane-vs-terraform-state-and-resilience.md) | Where is memory stored; what is the blast radius? |
| **This doc** | Prove changes and restore under pressure |

---

## Related notes

- [crossplane-vs-terraform-state-and-resilience.md](crossplane-vs-terraform-state-and-resilience.md)  
- [08-hcp-terraform/hcp-vs-open-source-cli.md](../../08-hcp-terraform/hcp-vs-open-source-cli.md) — state versions, run history  
- [07b — inspect state](../../07-maintain/07b-inspect-state/README.md) — `state pull`, surgery before restore  
- [declarative-terraform-and-kubernetes.md](../declarative-terraform-and-kubernetes.md) — GitOps overlap  

**External:** [Velero](https://velero.io/docs/), [HCP — state versions](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/state), [Kubernetes auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/).
