# Local stack

One configuration that uses the pieces you will keep using after the exam: a version pin, variables, a validation, `for_each`, a child module, a lifecycle rule, and an output. No cloud account.

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform state list
terraform output
terraform destroy
```

Then change `revision` in `terraform.tfvars` and plan again. `terraform_data.token` should be replaced (`+/-`, because `create_before_destroy` is set) and the file content should change with it.

`terraform plan` with no flags already loads `terraform.tfvars`.
