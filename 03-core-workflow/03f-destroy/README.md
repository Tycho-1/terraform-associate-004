# 3f — Destroy Terraform-managed infrastructure

Docs: [terraform destroy](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/destroy).

`terraform destroy` deletes every resource in the state. It is equivalent to planning with `-destroy` and applying that plan:

```bash
terraform destroy
terraform apply -destroy
terraform plan -destroy -out=destroy.tfplan
terraform apply destroy.tfplan
```

Destroy asks for confirmation unless you pass `-auto-approve` or apply a saved destroy plan.

## What it will delete

Only objects in this state. A file you created by hand, a cloud resource you created in the console, and a resource you removed from state with `terraform state rm` are all left alone.

Order is the reverse of the dependency graph. Terraform deletes things that nothing else depends on first, then the resources they depended on. You do not write the delete order yourself.

## One resource

```bash
terraform destroy -target=local_file.unit
terraform plan -destroy -target=local_file.unit
```

Targeting is still a last resort. Removing the `resource` block from configuration and applying also destroys that resource, and the plan shows the destroy in context with the rest of the configuration. Prefer that when you are editing code.

`terraform state rm` is the opposite: the resource block can stay or go, and Terraform forgets the object without deleting it.

## prevent_destroy

```hcl
lifecycle {
  prevent_destroy = true
}
```

A plan that would destroy that resource fails. `terraform destroy` fails too, until you remove the lifecycle argument and apply that change first (the lifecycle change itself does not destroy anything). See [4f](../../04-configuration/04f-dependencies-and-lifecycle).

## After the lab

```bash
cd 03-core-workflow/lab
terraform destroy
```

Then `terraform state list` prints nothing. The `.tf` files are still there. Another `apply` creates everything again. Destroy removes infrastructure, not configuration.
