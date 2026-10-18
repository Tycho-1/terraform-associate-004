# Terraform and Ansible

Both keep a description in git and try to make a machine match it. A second run that already matches should change nothing. The split is the transport and the memory. Ansible logs into a host, usually over SSH, and checks what is on that host. Terraform calls APIs through a provider and remembers what it created in a state file.

This sits next to [01a](../../01-infrastructure-as-code/01a-what-is-iac). The exam point is the one already in that note: Terraform is not the tool that SSHes in and installs packages. The Kubernetes comparison is [declarative Terraform and Kubernetes](../declarative-terraform-and-kubernetes.md).

## Where they match

| | Terraform | Ansible |
|---|---|---|
| Desired state, in git | `.tf` files | playbooks, roles, and an inventory |
| A unit of "make this true" | a resource (`aws_instance`, `local_file`) | a task whose module takes a state (`package: state=present`, `service: state=started`) |
| Run it again | a second apply with no drift plans nothing | a second play reports `ok` instead of `changed` when the host already matches |
| Drift | the next plan shows it; apply puts the object back | the next play puts the file, package, or service back |
| Inputs | variables and `terraform.tfvars` | variables, group vars, host vars |
| Reuse | a module | a role |
| Review before you run | `terraform plan` | `ansible-playbook --check` (check mode), when the module implements it |
| Order across a fleet | the graph decides what can run in parallel | plays run in the order written; hosts in a play run concurrently |

A package task and a Terraform resource are the same sentence at the small scale. "nginx should be installed." "This security group should exist." The module or the provider skips the work when that is already true. That is the similarity with a shell script removed: you stop writing `if` checks yourself.

Ansible is still a list of tasks. The playbook order is the order of execution. The declarative part is each module, not the play. Terraform has no task list. The whole configuration is the desired set, and the graph is computed from it.

## Where they split

**Ansible's main path is SSH (or WinRM).** It connects, copies a small program, runs it, and disconnects. There is no agent left on the host. The inventory is the list of machines that will accept that connection. A host that does not exist yet, or that has no SSH, is not a target until something else creates it and opens access.

**Terraform's main path is an API.** The AWS provider calls EC2. It does not log into the instance to create it. The instance can be created before any operating system is ready to accept SSH.

**Terraform remembers what it created. Ansible looks again each time.** State binds `aws_instance.web` to an instance id. The next plan updates that instance instead of creating a second one. Ansible has no state file of resources. It asks the host: is the package installed, does the file match, is the service running. Facts gathered at the start of a play are that inspection.

**Removing a description does different things.** Delete a `resource` block and the next Terraform apply destroys the object, because it is in state. Delete a package task from a playbook and the package stays installed. Ansible does not own "everything I used to mention." Making a package go away is a task you write (`state: absent`). Terraform treats the configuration as the full set of objects it manages.

**The preview is not equally strong.** `terraform plan` is a diff Terraform computed from state and the provider, and `apply` of a saved plan performs that diff. `ansible-playbook --check` asks each module to predict. Modules that do not implement check mode, or that have to change the host to know the result, will not give you a plan you can trust the way you trust a Terraform plan.

**Cloud modules exist in Ansible, and they are the overlap.** Collections such as `amazon.aws` can start an instance. That is the same API Terraform calls. Those tasks still do not build Terraform's graph or Terraform's state. They are a useful side path. They are not the reason to pick Ansible for a VPC, a cluster, and a database.

**Terraform can SSH, and that is the overlap in the other direction.** `remote-exec` and `local-exec` provisioners run a script during apply. HashiCorp treats them as a last resort. They do not record the files and packages the script created, so the next plan cannot converge them. Cloud-init, a configuration-management run, or an image built with Packer belongs there instead.

## What is stronger where

**Terraform is the better fit for the life of a cloud object.** Create the network, the instance, the database, the DNS record, the cluster. Update them when the configuration changes. Destroy them when they leave the configuration. One state file is what makes "remove it from the code" mean "delete it for real."

**Ansible is the better fit for the contents of a machine that already boots.** Users, SSH keys, packages, config files, a service enabled on boot. The host is long-lived, or it is one of many alike, and the work is "be like this" rather than "you are the instance I created last Tuesday." A network device or a bare-metal box with no cloud API is the same job: log in, converge, leave.

**Use them in that order when you need both.** Terraform creates the instance. The instance boots from an image that already has the packages, or cloud-init does the first boot, or a later Ansible run configures the OS. The instance id can be an Ansible inventory entry. The package list should not be a Terraform provisioner, because Terraform will not track those packages in state.

**Scheduled Ansible (AWX, Automation Controller) is a loop you add.** A nightly play corrects drift on the hosts. It is still SSH and a task list, run on a timer. It is not a controller watching an API. Kubernetes does that for pods. Terraform does not do it until the next apply. For a fleet of VMs, a scheduled play is the practical drift fix. For the VPC those VMs sit in, Terraform's plan is the better review.
