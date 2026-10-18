# Answers

Explanations point at the note that has the full version. Re-read that note if the one-line reason is not enough.

## True or false

1. **True.** Terraform plans the difference. No difference means no actions. [1a](../01-infrastructure-as-code/01a-what-is-iac)
2. **False.** `sensitive` redacts CLI and UI output. State still stores the value in plaintext. [4h](../04-configuration/04h-sensitive-data)
3. **False.** `validate` checks that the configuration is internally consistent. It does not call the provider API. [3c](../03-core-workflow/03c-validate)
4. **False.** Backend arguments are literals. The backend is configured before variables exist. Pass extra values with `-backend-config`. [6c](../06-state/06c-remote-backend)
5. **False.** A failed `check` is a warning. The run continues. A `precondition`, `postcondition`, or variable `validation` stops the run. [4g](../04-configuration/04g-custom-conditions)
6. **False.** `version` is only for registry modules. Local paths and Git URLs do not take it. Pin Git with `?ref=`. On the registry, `version` is **optional**; omitting it uses the **latest** at `init`. [5d](../05-modules/05d-module-versions)
7. **True.** That is the definition of ephemeral. `sensitive` is the mechanism that only redacts display. [4h](../04-configuration/04h-sensitive-data)
8. **False.** Drift detection reports the difference. It does not apply a fix. An apply, or a refresh-only apply, is a separate step. [8b](../08-hcp-terraform/08b-collaboration-governance)

## One answer

9. **B.** `terraform init` installs providers and modules. [3b](../03-core-workflow/03b-init)
10. **B.** The pessimistic constraint locks the rightmost component. `~> 1.2.3` stops before `1.3.0`. `~> 1.2` is the one that allows a minor bump and stops before `2.0.0`. [2a](../02-fundamentals/02a-provider-versions)
11. **B.** `provider = aws.dr` is an expression. A string `"aws.dr"` is not. The alias is declared on the `provider` block, not on the resource. [2c](../02-fundamentals/02c-multiple-providers)
12. **C.** Map keys are strings, and the variable is read as `var.vpc_cidrs`. A hyphen is not a valid bare identifier, so `.us-east-1` does not parse. [4d](../04-configuration/04d-complex-types)
13. **C.** `fmt` is whitespace and layout. Unknown attributes are `validate`. [3g](../03-core-workflow/03g-fmt)
14. **B.** A saved plan is applied exactly, with no extra prompt. `terraform show tfplan` only prints it. [3d](../03-core-workflow/03d-plan)
15. **B.** Default replacement is `-/+`. `create_before_destroy` flips it to `+/-`. [4f](../04-configuration/04f-dependencies-and-lifecycle)
16. **B.** Variable validation runs while the plan is built and fails the operation. The message has to be a full sentence. [4g](../04-configuration/04g-custom-conditions)
17. **B.** Ordinary arguments, including sensitive variables used as arguments, are plaintext in state. Write-only and ephemeral values are the exception. [2d](../02-fundamentals/02d-state), [4h](../04-configuration/04h-sensitive-data)
18. **C.** Callers see outputs only. Resource addresses inside the child are not in scope. [5b](../05-modules/05b-variable-scope)
19. **B.** `-refresh-only` writes discovered attributes into state and proposes no infrastructure changes. A normal apply would change infrastructure to match the configuration. [6d](../06-state/06d-drift-and-refactor)
20. **B.** `moved` updates the state address without destroying the object. `removed` forgets or destroys. `ignore_changes` is about attributes, not addresses. [6d](../06-state/06d-drift-and-refactor)
21. **B.** Levels run from `ERROR` up to `TRACE`. Treat the file like a credential and delete it. [7c](../07-maintain/07c-logging)
22. **B.** A run trigger queues a downstream run after a successful source apply. The downstream workspace usually reads outputs with `terraform_remote_state`. [8c](../08-hcp-terraform/08c-workspaces-and-projects)
23. **C.** Hard-mandatory cannot be overridden. Soft-mandatory can, by someone with override permission. Advisory warns and continues. [8b](../08-hcp-terraform/08b-collaboration-governance)
24. **B.** The `cloud` block selects the organization and workspace. `data "terraform_remote_state"` only reads outputs. [8d](../08-hcp-terraform/08d-cli-integration)

## Pick 2

25. **A and C.** `plan` and `apply` refresh unless you pass `-refresh=false`. `validate`, `fmt`, and `output` do not. [3d](../03-core-workflow/03d-plan)
26. **A and C.** Plugins are `init`. Formatting is `fmt`. Apply changes only what the diff requires. [3e](../03-core-workflow/03e-apply)
27. **A and C.** Validation and preconditions fail the run. Checks warn. `fmt -check` fails a CI job about style, and it is not a custom condition. Advisory policy does not stop the run. [4g](../04-configuration/04g-custom-conditions)
28. **B and D.** A data source reads. Its address is `data.<type>.<name>`. Removing it does not destroy the remote object. References to it are graph edges. [4a](../04-configuration/04a-resources-and-data)
29. **A and C.** The lock file pins provider versions. State, plan files, and crash logs hold secrets and machine-specific data. [2a](../02-fundamentals/02a-provider-versions), [2d](../02-fundamentals/02d-state)
30. **B and C.** HCL is the same. HCP Terraform adds remote execution, run history, variables, and permissions. `sensitive` does not encrypt a local state file. [8a](../08-hcp-terraform/08a-create-infrastructure)
31. **B and C.** Ephemeral values and write-only arguments are omitted from state. A sensitive variable used as a normal argument is still stored. `ignore_changes` does not remove a value already in state. [4h](../04-configuration/04h-sensitive-data)
32. **A and C.** References create implicit edges. `depends_on` is for edges with no reference. It does not name the resource and it does not change refresh. [4f](../04-configuration/04f-dependencies-and-lifecycle)
