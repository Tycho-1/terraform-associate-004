# HCP variables vs Terraform variables vs `TF_VAR_*`

Companion for [8c — Variable precedence](08c-workspaces-and-projects#variable-precedence), [4c — Where values come from](../04-configuration/04c-variables-and-outputs#where-values-come-from). Exam trap: **“HCP variable”** is not one thing — the UI has **two** kinds.

## Three names people mix up

| Name people say | What it actually is |
|---|---|
| **Terraform variable** (language) | A `variable "name" { ... }` block in `.tf` → used as **`var.name`** in the module |
| **HCP Terraform variable** (UI type) | A value stored on the **workspace** or **variable set**, injected into the run as **`var.name`** — same as `terraform.tfvars` on a laptop |
| **HCP environment variable** (UI type) | A key/value in the **shell** of the plan/apply process — used by providers (`AWS_*`), HCP (`TFC_*`), or **`TF_VAR_*`** |

Platform settings (workspace name, project, teams, execution mode) are **not** Terraform variables. They never become `var.*`.

## You must declare the variable in HCL

`TF_VAR_*` does **not** create a new input. It only **sets the value** of a variable **already declared** in configuration.

```hcl
variable "environment" {
  type = string
}
```

Without that block, setting `TF_VAR_environment=prod` in the workspace does nothing useful — Terraform has no `var.environment` to bind.

```hcl
resource "terraform_data" "example" {
  input = var.environment
}
```

**Define** inputs with `variable` blocks. **Supply** values with tfvars, `-var`, HCP “Terraform variables”, or **`TF_VAR_<name>`** in the environment.

## What `TF_VAR_<name>` does

Convention from the **Terraform CLI** (works on HCP remote runs too):

| Environment variable | Sets Terraform variable |
|---|---|
| `TF_VAR_environment=prod` | `var.environment` |
| `TF_VAR_instance_type=t3.micro` | `var.instance_type` |

Rules of thumb:

- Prefix is always **`TF_VAR_`** (all caps is conventional for env vars).
- The part after the prefix must match the **`variable` block name** (`environment`, not `var.environment`).
- Works for **root module** variables on that run (same as local CLI).
- For **complex types** (lists, maps), the value is still a string in the environment — often JSON; prefer HCP **Terraform variables** or `.tfvars` for nested objects.

```bash
# Laptop — same mechanism HCP uses when you add this as an *environment* variable
export TF_VAR_environment=dev
terraform plan
```

On **HCP Terraform**: Workspace → Variables → **Environment variable** → name `TF_VAR_environment`, value `dev`. That is **not** the same row as type **Terraform variable** `environment` — two ways to feed one `var.environment`; avoid setting both to different values.

## HCP UI: two columns, two namespaces

When you add variables in HCP (workspace or variable set):

| UI category | Becomes at run time | Example keys |
|---|---|---|
| **Terraform variable** | Input to `var.<key>` | `region`, `instance_type` |
| **Environment variable** | Process env | `AWS_ACCESS_KEY_ID`, `TFC_AWS_PROVIDER_AUTH`, `TF_VAR_region` |

- **`region` (Terraform variable)** → `var.region`
- **`TF_VAR_region` (environment variable)** → also `var.region`
- **`REGION` (environment variable)** → **not** a Terraform variable unless your HCL reads `env` somehow (providers do not map random env names to `var.*`)

Terraform variable **`region`** and environment variable **`REGION`** are **different keys** — they do not override each other ([8c](08c-workspaces-and-projects/README.md)).

## Where values come from — local CLI vs HCP

### Open-source CLI (single machine / CI)

Precedence among **value sources** (lowest → highest wins); see [4c](../04-configuration/04c-variables-and-outputs#where-values-come-from):

1. `TF_VAR_*` in the environment  
2. `terraform.tfvars` / `*.auto.tfvars`  
3. `-var` / `-var-file` on the command line  

`variable` **defaults** in HCL apply when no value is supplied.

### HCP Terraform (hosted values)

Among **HCP-stored** Terraform variables (highest wins first); see [8c](08c-workspaces-and-projects#variable-precedence):

1. Workspace Terraform variables  
2. Variable sets on that workspace  
3. Variable sets on the project  
4. Organization-wide variable sets  

Environment variables on the workspace (including `TF_VAR_*` and `AWS_*`) are merged into the **run environment**; they follow Terraform’s normal `TF_VAR_` rules for `var.*`. HCP precedence docs focus on **Terraform variable** layers; do not assume an env var overrides a workspace Terraform variable with the same logical name unless you know which mechanism you used (`TF_VAR_region` vs UI type “Terraform variable” `region`).

## Quick exam table

| Statement | True / false |
|---|---|
| HCP “Terraform variable” `foo` is the same as `variable "foo"` in HCL | **True** — same `var.foo` at run time |
| HCP environment variable `foo` is automatically `var.foo` | **False** — unless the name is `TF_VAR_foo` |
| `TF_VAR_foo` creates a `variable` block in code | **False** — you must declare `variable "foo"` in `.tf` |
| `TF_VAR_foo` sets `var.foo` when the block exists | **True** |
| Cloud credentials belong in Terraform variables | **Usually false** — use env vars / dynamic `TFC_*` ([provider-credentials.md](provider-credentials.md)) |

## Related

- [provider-credentials.md](provider-credentials.md) — `TF_VAR_*` vs `AWS_*` vs `TFC_*`
- [04c — variables](../04-configuration/04c-variables-and-outputs)
- [locals-vs-variables.md](../04-configuration/locals-vs-variables.md) — `var` vs `local`
