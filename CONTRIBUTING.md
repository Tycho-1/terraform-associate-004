# Contributing

Thanks for helping others prepare for the Terraform Associate (004) exam.

## What fits here

- Fixes to factual errors (with a link to [HashiCorp docs](https://developer.hashicorp.com/terraform) when possible)
- Clearer explanations, typos, broken links
- Small HCL examples that run without cloud credentials
- Extra practice questions (mark them as **original**, not from the exam)
- Deeper **Terraform vs other IaC** notes under [terraform-vs-iac/](terraform-vs-iac/) (comparisons are not exam objectives; keep Terraform-centric and link back to `01`–`08` where relevant)

## What we avoid

- Copying HashiCorp exam questions or answers
- Committing `terraform.tfstate`, `*.tfplan`, `.terraform/`, or secrets
- Provider-specific trivia that the [exam content list](https://developer.hashicorp.com/terraform/tutorials/certification-004/associate-review-004) says is out of scope

## Local checks before a PR

```bash
terraform fmt -recursive
```

From each directory you changed that contains a root module:

```bash
terraform init -input=false
terraform validate
```

CI runs `terraform fmt -check` and `terraform validate` on the main lab directories (see [.github/workflows/terraform.yml](.github/workflows/terraform.yml)).

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
