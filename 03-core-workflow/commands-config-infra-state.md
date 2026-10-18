# Commands: configuration, real infrastructure, and state

Exam-style matrix: does the command use **`.tf` configuration**, talk to **real infrastructure**, and **change state**?

| Command | Consults `.tf` files? | Consults real infra? | Modifies state? |
|---|---|---|---|
| `terraform plan` | **Yes** | **Yes** (refresh unless `-refresh=false`) | **No** infrastructure changes; refresh may **update state** during plan |
| `terraform apply` | **Yes** | **Yes** | **Yes** (records what changed) |
| `terraform plan -refresh-only` | **No** (refresh-only; no config diff) | **Yes** | **No** — preview only |
| `terraform apply -refresh-only` | **No** (for the purpose of the run) | **Yes** | **Yes** |
| `terraform state rm` | **No** | **No** | **Yes** |

Read the **`plan` / `apply` rows** for the usual workflow questions. Read **`-refresh-only` and `state rm`** for drift and state surgery.

### `plan -refresh-only` vs `apply -refresh-only`

Both modes **only refresh**: no create, update, or destroy driven by configuration. Neither changes real infrastructure to match `.tf`.

| Command | Writes state? |
|---|---|
| `terraform plan -refresh-only` | **No** — shows what **would** change in state after refresh |
| `terraform apply -refresh-only` | **Yes** — performs that refresh and **updates state** |

Typical flow: `terraform plan -refresh-only` (review) → `terraform apply -refresh-only` (commit state), or `plan -refresh-only -out=refresh.tfplan` → `terraform apply refresh.tfplan`.

**Do not confuse with normal `terraform plan`:** a default plan **refreshes during planning** and can **update state** as part of that refresh. **`plan -refresh-only`** is a special mode that **does not** persist state until you **apply**.

### `terraform apply -refresh-only`

**Rule:** **`-refresh-only` is purely about syncing state ↔ real infrastructure.** Terraform reads what exists remotely and updates **state** to match. It does **not** change real infrastructure to match your configuration, and it does **not** use the configuration to propose create/update/destroy actions for that run.

Use it when reality is correct and you want state to catch up (or before you edit `.tf` to match). See [6d](../06-state/06d-drift-and-refactor) and [3e](03e-apply).

Terraform still **loads** configuration so it knows which addresses exist; the exam point is that **desired configuration does not drive the plan** — only refresh does.

### `terraform state rm`

Removes an address from **state** only. **Does not destroy** the real infrastructure. Terraform **no longer tracks** the object; if the `resource` block remains, the next plan may try to **create** again unless you **import** or change configuration. Does not refresh from the API. Prefer a declarative `removed` block when you can. See [7b](../07-maintain/07b-inspect-state).

### Related commands (quick)

| Command | `.tf` | Real infra | State |
|---|---|---|---|
| `terraform validate` | Yes | No | No |
| `terraform fmt` | Yes (rewrites files) | No | No |
| `terraform output` | No | No | No (reads state) |
| `terraform init` | Yes | No | Backend wiring only |

Plan/apply refresh behavior: [3d](03d-plan). Locking during state writes: [6b](../06-state/06b-locking).
