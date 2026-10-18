# Workflow lab

A pet name and a file. No cloud account.

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
terraform state list
terraform apply -refresh-only
terraform destroy
```

Read the `+` lines on the first plan before you apply. After apply, change `content` in `terraform.tfvars` and plan again. You should see `~` on `local_file.unit` and no change to `random_pet.server`.

`terraform plan` with no extra flags already loads `terraform.tfvars`.
