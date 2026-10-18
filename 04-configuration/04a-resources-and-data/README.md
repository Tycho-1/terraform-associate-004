# 4a — Resource and data blocks

Docs: [Resources](https://developer.hashicorp.com/terraform/language/v1.12.x/resources), [Data sources](https://developer.hashicorp.com/terraform/language/v1.12.x/data-sources).

A `resource` block declares an object Terraform creates, updates, and destroys. It is in state. Terraform believes it manages that object.

A `data` block reads an object Terraform does not manage. It is a query. Destroying the configuration does not delete the thing the data source read. Data sources still appear in state, as a cache of the last read, and they refresh on plan.

```hcl
resource "local_file" "unit" {
  filename = "${path.module}/unit.txt"
  content  = "hello\n"
}

data "local_file" "unit" {
  filename = local_file.unit.filename
}
```

The address of the resource is `local_file.unit`. In expressions you read `local_file.unit.filename` — there is **no** `resource.` prefix. The address of the data source is `data.local_file.unit`. In expressions you read `data.local_file.unit.content` — the **`data.`** prefix is required. `resource.local_file.unit` is invalid. Forgetting `data.` or inventing `resource.` is a common wrong answer. See [4b](../04b-references).

## When you use each

| You want to… | Block |
|---|---|
| Create a file, instance, role, or record and keep owning it | `resource` |
| Look up an AMI, a VPC, a file, or a secret that already exists | `data` |
| Read a value only for this run and keep it out of state | `ephemeral` (see [4h](../04h-sensitive-data)) |

## What data sources can fetch

A **data source** is always a **read**: Terraform calls the provider (or a built-in data type), returns **attributes**, and caches the result in state. It does **not** create, change, or delete the thing it read. The **type** string (`aws_ami`, `terraform_remote_state`, …) defines what is being queried; each provider documents its own data sources.

| Example | What it fetches |
|---|---|
| `data "aws_ami" "ubuntu"` | Latest (or filtered) **AMI id** and image metadata from AWS |
| `data "aws_vpc" "selected"` | Attributes of an **existing VPC** (by id or filters) |
| `data "terraform_remote_state" "network"` | **Outputs** from another Terraform state (S3, GCS, `remote` / HCP Terraform, …) |
| `data "aws_iam_policy_document" "example"` | **Computed IAM policy JSON** from a declarative document block (no live AWS object yet) |
| `data "local_file" "unit"` | Contents of a **file on disk** (this repo’s lab) |
| `data "http" "example"` | **HTTP response** body (common in checks and tutorials) |
| `data "template_file" "cfg"` (legacy) | **Rendered template** string; prefer `templatefile()` in new config ([4e](../04e-expressions-and-functions)) |

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "my-org-terraform-state"
    key    = "network/terraform.tfstate"
    region = "eu-central-1"
  }
}

locals {
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::my-bucket/*"]
  }
}

resource "aws_iam_policy" "read" {
  policy = data.aws_iam_policy_document.s3_read.json
}
```

### Kinds of reads (exam mental model)

| Kind | Meaning | Examples |
|---|---|---|
| **Existing infrastructure** | Object already lives in the cloud/account | `aws_vpc`, `aws_subnet`, `azurerm_resource_group`, `google_compute_network` |
| **Lookup / filter** | Provider API search, “most recent” AMI, etc. | `aws_ami`, `aws_availability_zones` |
| **Computed document** | Provider builds a string (JSON, policy) from HCL nested blocks | `aws_iam_policy_document`, some `kubernetes_*` manifest data sources |
| **Another Terraform state** | Cross-stack wiring via **outputs only** | `terraform_remote_state` ([6c](../../06-state/06c-remote-backend), [8c](../../08-hcp-terraform/08c-workspaces-and-projects)) |
| **Local / HTTP / file** | Read from disk or URL | `local_file`, `http` |
| **Secrets** | Read from a secrets store (result usually still in state) | `vault_generic_secret` ([4h](../04h-sensitive-data)) |

**`template_file`:** Older configs used `data "template_file"` to render templates. In current Terraform prefer the **`templatefile()`** function in expressions ([4e](../04e-expressions-and-functions)). Exam snippets may still show `template_file`; recognize it as “rendered template content,” but write new config with `templatefile(path, vars)`.

Data sources use the same **`count`**, **`for_each`**, and **`provider`** meta-arguments as resources. Plan symbol for a read is **`<=`**. They participate in the dependency graph: `ami = data.aws_ami.ubuntu.id` creates an implicit edge.

General syntax: what counts as a top-level block vs a nested block vs an argument — [terraform-blocks.md](../terraform-blocks.md).

Both resource and data blocks take a type and a local name: `resource "<type>" "<name>"`. The type string is defined by the provider (`aws_vpc`, `local_file`). Terraform infers which provider plugin to use from that type: the part before the first underscore (`aws_vpc` → provider `aws`). You do not repeat the provider name in the block unless you need an alias (`provider = aws.dr`). See [2b](../../02-fundamentals/02b-how-providers-work). The local name (`shared`, `unit`) is yours. Together, type plus local name must be unique in the module.

## Arguments, attributes, meta-arguments

**Arguments** are what you set (`filename`, `content`). **Attributes** are what you can read afterwards (`id`, `content_base64`). Some arguments are also attributes.

**Meta-arguments** are Terraform core, available on resources regardless of provider: `depends_on`, `count`, `for_each`, `provider`, `lifecycle`. They are not sent to the API as-is. `provider` schemas do not list them.

## Behavior on the next apply

- Change a resource argument: plan shows an update or a replacement.
- Change a data source argument: Terraform reads a different object. Nothing is deleted at the remote end because Terraform never owned it.
- Remove a `resource` block: the next apply destroys the real object.
- Remove a `data` block: Terraform forgets the cached read. The real object stays.

## Apply this folder

```bash
cd 04-configuration/04a-resources-and-data
terraform init
terraform apply
terraform state list
```

State lists both `local_file.unit` and `data.local_file.unit`. Then `terraform destroy` deletes the file and leaves no managed resource. The data source did not own a second file.
