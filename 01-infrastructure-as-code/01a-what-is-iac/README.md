# 1a — Explain what IaC is

Docs: [What is Terraform?](https://developer.hashicorp.com/terraform/intro/v1.12.x), [Introduction to Infrastructure as Code](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/infrastructure-as-code).

Infrastructure as code means the servers, networks, databases, and DNS records are described in files that both people and tools can read. Those files are the source of truth. A tool creates and changes the real infrastructure so it matches the files.

Terraform's language is declarative. You write the desired end state. Terraform computes the difference between that state and what already exists, then applies only the difference. You do not write the create/update/delete steps yourself. Kubernetes is declarative in the same sense, and reconciles in a loop instead of on `apply`. The comparison is in [declarative-terraform-and-kubernetes.md](../../terraform-vs-iac/declarative-terraform-and-kubernetes.md).

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123456789abcdef0"
  instance_type = "t3.micro"
}
```

That block says "an instance with these attributes should exist." It does not say "call RunInstances, then if the type changed call ModifyInstanceAttribute." The AWS provider turns the desired state into API calls. Terraform core never talks to AWS directly.

## The three pieces

1. **Configuration** — `.tf` files. Desired state, written in HCL.
2. **State** — Terraform's record of the real objects it created, and the attributes it last read. This is how it knows which instance belongs to `aws_instance.web`.
3. **Providers** — plugins that know one API (AWS, Azure, Kubernetes, GitHub, a DNS host, a random-number generator).

A run is: read configuration, refresh state from the provider, diff, ask the provider to close the gap, write the new state.

## Declarative vs a script

A shell script is imperative. It runs steps. Run it twice and it may try to create the same object twice, or you fill it with `if exists` checks.

Terraform is idempotent at the model level. A second `apply` with the same configuration and no outside changes plans nothing. The provider still gets called during refresh, and the result of that refresh is "no difference."

## What a question is asking

A statement is about IaC when it says the infrastructure definition is stored as code, reviewed, and applied by a tool to reach a desired state.

A statement is about something else when it says Terraform is a configuration management tool that SSHes in and installs packages (that is Ansible/Puppet territory; the comparison is in [terraform-and-ansible.md](../../terraform-vs-iac/ansible/terraform-and-ansible.md)), or that Terraform replaces the cloud console for every product the provider has not implemented.

Terraform provisions infrastructure. Provisioners (`local-exec`, `remote-exec`) can run scripts, and HashiCorp treats them as a last resort. Bootstrapping a machine's OS is a job for cloud-init, a configuration management tool, or an image builder such as Packer.
