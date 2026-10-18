# 2a — Install and version providers

Docs: [Provider requirements](https://developer.hashicorp.com/terraform/language/v1.12.x/providers/requirements), [dependency lock file](https://developer.hashicorp.com/terraform/language/v1.12.x/files/dependency-lock), [lock and upgrade tutorial](https://developer.hashicorp.com/terraform/tutorials/configuration-language/provider-versioning).

Terraform itself is a single binary you install from HashiCorp (package, or `terraform` on your PATH). Providers are separate **compiled plugin binaries** for your platform (for example `linux_amd64`). You do not install them with the OS package manager. `terraform init` downloads signed zip archives and unpacks the executable under `.terraform/providers/`.

Terraform **cannot** compile a provider from Go source or load one straight from a provider repository checkout. Day-to-day use always means a **released** plugin binary from the registry, a private registry, or a mirror. Writing your own provider is a separate SDK and release process; your root module only declares which published plugin to install. Example: a proprietary user API on Azure needs a **custom provider** you build and publish (often to the private registry), then reference in `required_providers` — see [2b — proprietary APIs use case](../02b-how-providers-work#use-case-proprietary-apis-on-azure).

```hcl
terraform {
  required_version = ">= 1.12.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
```

`required_version` is the Terraform CLI. `version` inside `required_providers` is the provider plugin. Mixing those up is a common wrong answer.

The **`version`** constraint on each provider in `required_providers` is **optional** (Terraform can install the latest plugin if you omit it). You should still set one in real configs; the lock file records the exact build after `init`. Registry **module** `version` is also optional — see the summary table in [5d](../../05-modules/05d-module-versions).

`source` is `hostname/namespace/type`, and the hostname defaults to `registry.terraform.io`. `hashicorp/random` means `registry.terraform.io/hashicorp/random`.

## Version constraint syntax

The operator sits in the `version` string. Several constraints can be combined with commas.

| Constraint | Allows |
|---|---|
| `1.2.3` or `= 1.2.3` | only 1.2.3 |
| `>= 1.2.0` | 1.2.0 and anything newer |
| `!= 1.2.3` | anything except 1.2.3 |
| `~> 1.2` | `>= 1.2.0` and `< 2.0.0` |
| `~> 1.2.3` | `>= 1.2.3` and `< 1.3.0` |
| `>= 1.2.0, < 1.5.0` | the range between them |

The pessimistic operator `~>` locks the rightmost component. `~> 1.2` can move the minor version. `~> 1.2.3` can move only the patch version. People read `~> 1.2.0` as "any 1.x" and that reading is wrong: it stops before 1.3.0.

## The lock file

`terraform init` writes `.terraform.lock.hcl`. It records:

- the exact provider version that was selected
- the hashes of the plugin zip for each platform

Commit the lock file. The next `terraform init` on another machine downloads that exact version, as long as the version still satisfies `required_providers`.

`terraform init -upgrade` selects the newest version allowed by the constraint and rewrites the lock file. Review that diff the same way you review an application dependency bump.

Without a version constraint, `init` installs the latest version and the lock file still pins it afterwards. A constraint belongs in the configuration so a future `-upgrade` cannot jump a major version by surprise.

## Where plugins come from

By default, `terraform init` downloads providers from the **public Terraform Registry** at `registry.terraform.io`. The `source` in `required_providers` is that address (`hashicorp/aws` is shorthand for `registry.terraform.io/hashicorp/aws`).

Providers do **not** have to come from the public internet. Organizations can control how plugins are distributed for security, compliance, air-gapped networks, and faster repeat installs. `terraform init` still performs the install; only the **download location** changes. Configuration in the `.tf` files (`required_providers`, version constraints, lock file) stays the same.

| Source | Role |
|---|---|
| **Public registry** | Default. `init` resolves versions and downloads signed plugin zips. |
| **Private registry** | Modules and providers published inside an organization. HCP Terraform and Terraform Enterprise host a **private registry** with its own hostname. `source` in `required_providers` points at that host instead of `registry.terraform.io`. Same workflow as the public registry, different trust boundary. See [8b](../../08-hcp-terraform/08b-collaboration-governance). |
| **Filesystem mirror** | A directory on disk laid out like the registry. `init` reads plugin zips from the mirror when the CLI config (`~/.terraformrc` or `terraform.rc`) directs installation there. Used for offline installs and golden copies vetted by security. |
| **Network mirror** | An internal HTTP service that serves the same layout as the registry API. `init` talks to the mirror instead of the public registry. Common in enterprises that block outbound access to `registry.terraform.io`. |
| **Provider cache** | Not a separate “source,” but a shared local cache (`plugin_cache_dir` in the CLI config, or `TF_PLUGIN_CACHE_DIR`). After the first download, later `init` runs in other directories can reuse the same plugin binary instead of fetching again. Speeds up laptops and CI agents; does not replace mirrors when the network has no registry access at all. |

All of these are configured in the **Terraform CLI settings file**, not in `terraform { }` blocks inside your module. Backend blocks already cannot use variables; provider installation mirrors are the same idea: they are environment- and machine-level policy.

```text
required_providers in .tf  ->  terraform init  ->  registry | private registry | mirror | cache
                                                      |
                                                      v
                                            .terraform/providers/...
```

What the exam checks:

- **`terraform init` installs providers** (and modules). `apply` does not download plugins.
- **`required_providers`** names the provider and constrains the version. **`source`** names which registry host and namespace own the plugin.
- **`.terraform.lock.hcl`** pins the exact version and hashes after the first successful `init`, whether the zip came from the public registry or a mirror.
- Providers can be installed **without** reaching the public internet when mirrors or a private registry are configured. That does not change how state, plan, or `required_providers` work.

Docs: [Provider requirements](https://developer.hashicorp.com/terraform/language/v1.12.x/providers/requirements), [Terraform CLI settings](https://developer.hashicorp.com/terraform/cli/config/config-file), [Provider installation](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-installation).

## Try it

```bash
cd 02-fundamentals/02a-provider-versions
terraform init
cat .terraform.lock.hcl
terraform init -upgrade
```

`versions.tf` asks for `~> 3.6`, so `-upgrade` may move 3.6.x to a newer 3.x and must not move to 4.0.0.
