# Publishing on GitHub

Checklist before the first push (after you run `git init` locally).

## Already in this repo

- [LICENSE](LICENSE) (MIT)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [README.md](README.md) disclaimer (unofficial, not HashiCorp exam content)
- [.gitignore](.gitignore) — state, `.terraform/`, plans, local lab outputs
- [.gitattributes](.gitattributes) — LF line endings
- [.github/workflows/terraform.yml](.github/workflows/terraform.yml) — `fmt -check` and `validate` on lab roots
- Reference platforms — EKS, GKE, AKS all point at `github.com/Tycho-1/...`

## Before `git add`

```bash
cd /path/to/terraform-associate-004
terraform fmt -recursive
git status   # no *.tfstate, no .terraform/ directories staged
```

If old state or `.terraform` folders exist locally, they should be **ignored**, not deleted unless you want a clean re-`init`.

## Suggested GitHub settings

| Field | Suggestion |
|---|---|
| **Repository name** | `terraform-associate-004` (or `terraform-associate-study`) |
| **Description** | Study notes, runnable labs, and practice questions for HashiCorp Terraform Associate (004) — unofficial |
| **Topics** | `terraform`, `hashicorp`, `terraform-associate`, `hcp-terraform`, `iac`, `study-guide` |
| **License** | MIT (matches [LICENSE](LICENSE)) |

## First-time git (when you are ready)

```bash
git init
git add .
git status   # review
git commit -m "Initial public study guide for Terraform Associate 004"
git remote add origin git@github.com:Tycho-1/terraform-associate-004.git
git push -u origin main
```

Create the empty repository on GitHub first, or use `gh repo create`.

## After push

- Confirm the **Actions** tab shows green for `Terraform` workflow
- Pin the repo or add a link from your profile if you share it widely
