# 5 — Terraform modules

A module is a directory of `.tf` files. The directory where you run Terraform is the root module. Every `module` block calls a child module.

| Note | Objective |
|---|---|
| [05a-module-sources](05a-module-sources) | Where a module can come from |
| [05b-variable-scope](05b-variable-scope) | What a child can see |
| [05c-use-modules](05c-use-modules) | Call a local module, read its outputs |
| [05d-module-versions](05d-module-versions) | Pin a registry module |

```bash
cd 05-modules/05c-use-modules
terraform init
terraform apply
```
