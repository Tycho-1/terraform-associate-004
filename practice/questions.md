# Practice questions

Original questions in the three formats HashiCorp uses. They are not from the exam. The public samples are explained in [00-before-the-exam](../00-before-the-exam).

Do the set with the answers file closed. Write the letter, or "true"/"false", before you check [answers.md](answers.md).

Multiple-answer questions say how many to pick.

## True or false

1. A second `terraform apply` with the same configuration, and no drift, plans no changes.
2. Marking a variable `sensitive = true` encrypts that value in the state file.
3. `terraform validate` contacts the cloud provider to check that credentials work.
4. Arguments inside a `backend` block may use `var` and `local` values.
5. A `check` block that fails stops `terraform apply`.
6. `version` on a `module` block is valid for a module loaded from a local path.
7. An ephemeral value is omitted from the plan and from state.
8. Drift detection in HCP Terraform changes infrastructure back to match the configuration.

## One answer

9. Which command downloads provider plugins into `.terraform/`?
   - A. `terraform apply`
   - B. `terraform init`
   - C. `terraform validate`
   - D. `terraform fmt`

10. What does `~> 1.2.3` allow?
    - A. `>= 1.2.3` and `< 2.0.0`
    - B. `>= 1.2.3` and `< 1.3.0`
    - C. exactly `1.2.3`
    - D. any version except `1.2.3`

11. A resource `aws_instance.backup` must use the provider configuration that has `alias = "dr"`. Which meta-argument is correct?
    - A. `provider = "aws.dr"`
    - B. `provider = aws.dr`
    - C. `alias = "dr"`
    - D. `region = "dr"`

12. Which expression reads the `us-east-1` entry of `variable "vpc_cidrs"` declared as `type = map(string)`?
    - A. `vpc_cidrs["us-east-1"]`
    - B. `var.vpc_cidrs[0]`
    - C. `var.vpc_cidrs["us-east-1"]`
    - D. `var.vpc_cidrs.us-east-1`

13. Which command rewrites `.tf` files to canonical style and does not check whether attributes exist?
    - A. `terraform validate`
    - B. `terraform plan`
    - C. `terraform fmt`
    - D. `terraform apply -refresh-only`

14. You saved a plan with `terraform plan -out=tfplan`. Which command performs those actions and does not prompt?
    - A. `terraform apply`
    - B. `terraform apply tfplan`
    - C. `terraform plan tfplan`
    - D. `terraform show tfplan`

15. What does `lifecycle { create_before_destroy = true }` change about a replacement?
    - A. Terraform refuses to replace the resource.
    - B. The new object is created, then the old object is destroyed (`+/-`).
    - C. The old object is destroyed, then the new object is created (`-/+`).
    - D. Terraform ignores every argument on the resource.

16. A variable validation fails. What happens?
    - A. Apply continues and records a warning.
    - B. Terraform stops the operation and prints `error_message`.
    - C. The value is stored and marked sensitive.
    - D. Terraform sets the variable to its default.

17. Which value is stored in state when you use an ordinary variable for a database password?
    - A. Only a hash of the password.
    - B. The password, in plaintext JSON.
    - C. Nothing, because variables never reach state.
    - D. The password, encrypted with the Terraform binary's key.

18. A child module declares `variable "prefix"` and `output "name"`. From the root module, how do you read the generated name?
    - A. `var.prefix`
    - B. `random_pet.this.id`
    - C. `module.pet.name`
    - D. `module.pet.random_pet.this.id`

19. Which operation updates state to match real infrastructure and does not change that infrastructure?
    - A. `terraform apply`
    - B. `terraform apply -refresh-only`
    - C. `terraform fmt -check`
    - D. `terraform validate`

20. You renamed `random_pet.server` to `random_pet.renamed` and want Terraform to keep the same pet. What do you add?
    - A. A `removed` block with `destroy = false`.
    - B. A `moved` block from `random_pet.server` to `random_pet.renamed`.
    - C. `lifecycle { ignore_changes = all }`.
    - D. `terraform state push`.

21. `TF_LOG=TRACE` is set for a plan. Which statement is accurate?
    - A. The plan skips resources that have sensitive attributes.
    - B. The log is the most verbose level and can contain secrets.
    - C. TRACE encrypts the state file.
    - D. TRACE is required for `terraform validate` to run.

22. Two HCP Terraform workspaces, `network` and `app`, are in one project. A successful apply in `network` should queue a plan in `app`. What is that link called?
    - A. A variable set
    - B. A run trigger
    - C. A CLI workspace
    - D. A policy set

23. A Sentinel policy is enforced as hard-mandatory and the plan violates it. What happens?
    - A. Apply runs, and the violation is a warning.
    - B. The run stops, and a workspace admin can override it.
    - C. The run stops, and the policy cannot be overridden.
    - D. Terraform rewrites the configuration so the policy passes.

24. Which block sends state to HCP Terraform and is mutually exclusive with `backend`?
    - A. `provider "cloud"`
    - B. `terraform { cloud { ... } }`
    - C. `data "terraform_remote_state"`
    - D. `backend "local"`

## Pick 2

25. Which two commands refresh state unless you pass an extra flag? Pick 2.
    - A. `terraform plan`
    - B. `terraform validate`
    - C. `terraform apply`
    - D. `terraform fmt`
    - E. `terraform output`

26. Which two statements describe `terraform apply` of a normal configuration? Pick 2.
    - A. It makes the infrastructure changes from the plan.
    - B. It downloads provider plugins.
    - C. It updates state to record what it changed.
    - D. It rewrites `.tf` files to canonical style.
    - E. It destroys and recreates every resource on every run.

27. Which two constructs stop the run when their condition is false? Pick 2.
    - A. `validation` on a variable
    - B. `check` / `assert`
    - C. `precondition`
    - D. `terraform fmt -check`
    - E. an advisory policy

28. Which two are true about a `data` block? Pick 2.
    - A. Terraform creates the object it names.
    - B. Terraform reads an existing object.
    - C. Removing the data block from configuration destroys that remote object.
    - D. Its address is prefixed with `data.`.
    - E. It cannot participate in the dependency graph.

29. Which two belong in version control for a shared module repository? Pick 2.
    - A. `.terraform.lock.hcl`
    - B. `terraform.tfstate`
    - C. `*.tf`
    - D. a saved `tfplan` file that contains a database password
    - E. `crash.log` from a TRACE run

30. Which two does HCP Terraform add beyond a local backend? Pick 2.
    - A. A different HCL syntax for `resource` blocks.
    - B. Remote runs with saved plan history.
    - C. Variable sets and team permissions.
    - D. The ability to skip writing a configuration.
    - E. Automatic encryption of every value marked `sensitive` inside a local `terraform.tfstate` on your laptop.

31. You need a password to reach the AWS provider during a run, and you do not want that password stored in state. Which two mechanisms fit? Pick 2.
    - A. `sensitive = true` on the variable, used in a normal resource argument
    - B. an ephemeral variable or ephemeral resource
    - C. a write-only argument such as `password_wo`, with `password_wo_version`
    - D. `terraform output -raw`
    - E. `lifecycle { ignore_changes = [password] }`

32. Which two statements about `depends_on` are accurate? Pick 2.
    - A. A reference like `random_pet.server.id` already creates a dependency, with no `depends_on`.
    - B. `depends_on` is how you give a resource its name.
    - C. `depends_on` expresses an edge the configuration does not show through a reference.
    - D. `depends_on` encrypts the upstream resource's attributes.
    - E. `depends_on` disables state refresh for that resource.
