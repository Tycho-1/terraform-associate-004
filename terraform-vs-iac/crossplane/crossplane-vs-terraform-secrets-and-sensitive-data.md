# Crossplane vs Terraform — secrets, sensitive, and ephemeral

Seventh note in the Crossplane series. Terraform mechanics are **Associate 4h** ([04h — sensitive, ephemeral, write-only](../../04-configuration/04h-sensitive-data/README.md)) plus **HCP env vars** ([hcp-variables-and-tf-var.md](../../08-hcp-terraform/hcp-variables-and-tf-var.md), [provider-credentials.md](../../08-hcp-terraform/provider-credentials.md)).

**Summary:** Crossplane does **not** have `sensitive`, `ephemeral`, or `TF_VAR_*`. Secrets are **Kubernetes Secrets** (and whatever backs them — ESO, Vault, cloud identity). GitOps YAML should **reference** secrets, not contain them. External Secrets Operator is one common sync path, not the only one.

Related: [variables & inputs](crossplane-vs-terraform-variables-and-inputs.md), [state & resilience](crossplane-vs-terraform-state-and-resilience.md) (secrets in state vs etcd).

---

## Terraform — three different ideas (exam-critical)

| Mechanism | What it does | Still in **state**? |
|---|---|---|
| **`sensitive = true`** | Redacts in CLI/UI logs | **Yes** — state/plan can still hold plaintext |
| **`TF_VAR_*` / HCP env / `-var`** | Injects value at **run time**, not in Git | **Yes**, if passed into normal resource attributes |
| **`ephemeral = true` / `ephemeral` blocks** | Usable only in ephemeral contexts | **No** — omitted from plan/state |
| **Write-only args** (`password_wo` + version) | Provider gets value on apply | **No** stored password — plan tracks version field |
| **Provider env** (`AWS_*`, dynamic creds) | Auth without keys in HCL | Keys not in `.tf`; **other** attrs may still be in state |

Exam trap: **“sensitive variable”** → can still be **plain text in state**. Only **ephemeral** / **write-only** (for that attribute) keep the secret out of state.

---

## Crossplane — no HCL flags; object + reference model

Everything sensitive is supposed to live **outside Git** and **outside Claim `.spec` literals**:

```text
Git (Claim YAML)          Kubernetes                 Cloud
────────────────          ──────────                 ─────
spec.passwordRef    ──►   Secret  ──► patch ──►   MR forProvider
     (name/key)            (etcd)                    (apply to API)

ProviderConfig        ──► Secret / IRSA / WI  ──►  cloud API auth
```

| Terraform idea | Crossplane pattern |
|---|---|
| **`sensitive` variable** | **No equivalent flag** — use a **Secret**; restrict **RBAC** (`get/list/watch`); enable **encryption at rest** for etcd |
| **`TF_VAR_db_password` / HCP env** | **Secret** created by CI, **ESO** sync, or **SealedSecrets/SOPS**; Composition patches **fromSecretKey** (or provider-specific ref) |
| **Never commit secrets** | **GitOps**: only `secretRef`, `credentials.secretRef`, `writeConnectionSecretToRef` in tracked YAML |
| **`ephemeral` / not in state** | **No state file** — but Secret **does** persist in **etcd** until deleted; connection secrets persist for apps |
| **Write-only password on resource** | Provider generates password → **`writeConnectionSecretToRef`** (connection Secret); password not in Claim spec |
| **Provider credentials** | **`ProviderConfig`** — `secretRef`, **IRSA**, **Workload Identity**, **Pod Identity** (prefer **no long-lived key** in Git) |
| **Vault provider** | **Vault** + ESO / CSI / injector → K8s **Secret** → Crossplane reads ref (same as other apps) |

Crossplane’s “sensitive” is **operational**: **RBAC**, **encryption at rest**, **audit**, **no literals in Git** — not a field on the CR schema that redacts `kubectl get`.

---

## External Secrets Operator and other paths

ESO is one way to **populate** Secrets. Full picture:

| Layer | Options |
|---|---|
| **How Secret gets into cluster** | `kubectl create secret` (break-glass), CI/CD, **External Secrets Operator** (Vault, AWS SM, GCP SM, …), **Sealed Secrets**, **SOPS** + Flux, **CSI secret store** volume |
| **How Crossplane consumes it** | **ProviderConfig** `credentials.secretRef`; Composition **patches** from Secret; MR **connectionSecret** refs |
| **Avoid static cloud keys** | **IRSA** (EKS), **Workload Identity** (GKE), **AKS workload identity** — ProviderConfig uses **in-cluster identity**, not `AWS_ACCESS_KEY_ID` in a Secret |
| **App team receives DB password** | Provider writes **connection Secret** in team **namespace** (like a sensitive **output** to a secure channel) |
| **GitOps repo** | Claims with **`passwordSecretRef`** / no password field at all — platform generates via MR |

ESO answers: *“Vault/AWS SM is source of truth; cluster Secret stays in sync.”*  
Crossplane answers: *“Use that Secret (or cloud identity) when reconciling MRs.”*

---

## Side-by-side scenarios

### Cloud API credentials for the provider

| **Terraform** | **Crossplane** |
|---|---|
| `provider "aws" { }` + env / shared config / HCP dynamic credentials | **`ProviderConfig`** with IRSA or `secretRef` to Secret containing keys (last resort) |

### Database password on create

| **Terraform** | **Crossplane** |
|---|---|
| `random_password` + `sensitive` output (still in state unless ephemeral/write-only path) | MR with **auto-generated** password + **`writeConnectionSecretToRef: team-ns/orders-db`** |
| `password_wo` + `password_wo_version` (not in state) | Generated in cloud; only **Secret** in cluster holds connection string — still **etcd**, protect RBAC |

### App team passes password in input

| **Terraform** | **Crossplane** |
|---|---|
| `variable "password" { sensitive = true }` — anti-pattern in Git | **Anti-pattern:** `spec.password: "..."` in Git. **Better:** team creates **Secret** in namespace; Claim references it; or platform generates |

### Reading a secret only for this reconcile

| **Terraform** | **Crossplane** |
|---|---|
| `ephemeral` variable into `provider` or write-only arg — gone after run | Controller reads **Secret** each reconcile; value remains in Secret object (not “ephemeral” at storage layer) |

---

## Where secrets still leak (both worlds)

| Risk | **Terraform** | **Crossplane** |
|---|---|---|
| **Central store** | **State** / plan artifacts in S3, HCP | **etcd** (CR `.spec` / `.status`, **Secret** data) |
| **CI logs** | `plan` if not redacted | `kubectl` events, controller logs if spec logged |
| **Git** | `.tfvars` committed by mistake | Claim with literal password |
| **Audit** | State versions, run history | K8s audit log, Git history of refs (refs are OK; values are not) |

`sensitive` and “we use ESO” do not replace **locking down state/etcd** and **rotation**.

---

## GitOps YAML — what is safe to commit

| OK in Git | Not OK in Git |
|---|---|
| Claim with `secretRef: { name: orders-db-creds, key: password }` | `password: hunter2` in `spec` |
| ProviderConfig with `secretRef` **name** only | Base64 or plain credential in manifest |
| Composition (no secret values) | EnvironmentConfig with live production passwords (use Secret refs or ESO target) |

Flux/Argo **do not** magically encrypt Secrets in git unless you use **SOPS/SealedSecrets** — same discipline as not committing `terraform.tfvars` with secrets.

---

## Mapping table (exam + platform)

| Terraform | Crossplane |
|---|---|
| `sensitive = true` | RBAC + encryption at rest + no `kubectl get secret -o yaml` for humans |
| `ephemeral` | No direct analog; closest is **short-lived cloud creds** via identity, not persisted in CR |
| `password_wo` | Provider-generated + **connection Secret**; spec does not hold password |
| `TF_VAR_*` / HCP env | Secret sync (ESO/CI) or identity-based **ProviderConfig** |
| `random_password` in state | Cloud-side generate + **writeConnectionSecretToRef** |
| Vault provider | Vault → ESO/CSI → K8s Secret → Crossplane ref |

---

## Related notes

- [04h — sensitive data](../../04-configuration/04h-sensitive-data/README.md)  
- [08 — provider credentials](../../08-hcp-terraform/provider-credentials.md)  
- [crossplane-vs-terraform-variables-and-inputs.md](crossplane-vs-terraform-variables-and-inputs.md)  
- [crossplane-vs-terraform-state-and-resilience.md](crossplane-vs-terraform-state-and-resilience.md)  

**External:** [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/), [External Secrets Operator](https://external-secrets.io/), [Crossplane — ProviderConfig](https://docs.crossplane.io/latest/concepts/provider-configs/).
