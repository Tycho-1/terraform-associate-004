# 7a — Import existing infrastructure

Docs: [terraform import](https://developer.hashicorp.com/terraform/cli/v1.12.x/commands/import), [import usage](https://developer.hashicorp.com/terraform/cli/v1.12.x/import), [import tutorial](https://developer.hashicorp.com/terraform/tutorials/state/state-import).

Import records an object that already exists so Terraform manages it from now on. Import does not create the object, and it does not change it. It writes state. The next plan diffs your configuration against the object that was just imported.

You always need two things: a `resource` block that describes the object, and the provider-specific ID of the real object (`i-abc123`, a bucket name, a full Azure resource id).

### Use case: VMs created with `gcloud` (or the console)

**Scenario.** You already provisioned VMs on **GCP** with **`gcloud`** (or the UI). You want Terraform to **manage** them instead of creating duplicates.

**You need both** (exam “pick two” style):

| Step | Why |
|---|---|
| **Add a `resource` block** for the existing VM (`google_compute_instance`, …) | Terraform must know **what** to manage and **desired configuration** for future plans. A resource block alone does **not** attach existing infrastructure — `apply` would try to **create** a second VM. |
| **Import** into state (`import` block or `terraform import`) | Records the **existing** VM’s provider id in state at that resource address. Import does **not** create or change the VM; it only updates **state**. |

```hcl
import {
  to = google_compute_instance.web
  id = "projects/my-proj/zones/europe-west1-b/instances/my-vm"
}

resource "google_compute_instance" "web" {
  name         = "my-vm"
  machine_type = "e2-medium"
  zone         = "europe-west1-b"
  # ... match reality or use plan -generate-config-out after import block
}
```

```bash
terraform plan -generate-config-out=generated.tf   # optional: draft resource from live VM
terraform apply                                    # applies import + any other changes
```

Or imperative: write the `resource` block first, then `terraform import google_compute_instance.web projects/.../instances/my-vm`.

**Wrong alone:** only an `import` block with **no** `resource` (nothing to import **to**). Only a `resource` block with **no** import (Terraform thinks the VM does not exist yet → plans **create**).

Same pattern for AWS (`aws_instance` + instance id), Azure (`azurerm_linux_virtual_machine` + Azure resource id), and any provider.

## Declarative import (the current way)

```hcl
import {
  to = aws_instance.web
  id = "i-0123456789abcdef0"
}

resource "aws_instance" "web" {
  # configuration you want Terraform to manage
}
```

```bash
terraform plan -generate-config-out=generated.tf
terraform apply
```

`-generate-config-out` asks the provider to write a matching `resource` block from the live object. You then edit that file: generated configuration is a starting point, often with arguments you will delete or with values you will replace with variables. The `import` block is applied as part of the plan, so the import is reviewed like any other change.

After a successful apply, the object is in state. You can remove the `import` block. Leaving it causes the next plan to fail once the address is already managed, because import expects to add it.

`import` blocks can use `for_each` and `id` expressions, so a list of existing ids can be imported in one plan.

## Imperative import

```bash
terraform import aws_instance.web i-0123456789abcdef0
```

The `resource "aws_instance" "web"` block must already be in the configuration. The command only fills in state. It does not write the `.tf` file for you. You then run `terraform plan` and edit the configuration until the plan is empty. Until the plan is empty, the next apply will change the real object to match whatever you wrote.

## After import

A non-empty plan means the configuration and the live object disagree. Decide which side wins:

- edit the configuration to match the live object, so Terraform takes ownership without changing it
- apply, which changes the live object to match the configuration

Identity arguments that force replacement (`name` on some resources, `filename` on `local_file`) are the ones to get right before the first post-import apply.

## What import is not

- It is not `terraform state mv` (that renames an address already in state).
- It is not a refresh (refresh updates attributes of objects already in state).
- It does not import a whole account. Each object has an ID and a resource address.
- The ID format is defined by the provider, not by Terraform core. You look it up on the resource's registry page. The exam will not ask you to memorize an AWS ARN layout; it will ask what import changes (state) and what you must already have (a resource block, or a generate-config plan).
