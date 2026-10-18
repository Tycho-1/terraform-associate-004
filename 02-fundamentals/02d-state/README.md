# 2d — How Terraform uses and manages state

Docs: [Purpose of Terraform state](https://developer.hashicorp.com/terraform/language/v1.12.x/state/purpose).

State is a JSON file that maps the addresses in your configuration to the real objects a provider created. `random_pet.primary` is an address. The pet name that came back from the provider is stored next to it. On the next run Terraform updates that pet instead of creating another one.

State also stores:

- attribute values, so Terraform can show a diff without guessing
- dependency metadata discovered during apply
- outputs
- a serial number and a lineage id, so backends can detect two people writing at once

## Why it exists

**Mapping.** Configuration says `random_pet.primary`. The real object has a generated name. State binds the two. Rename the address without telling Terraform and it plans to destroy the old object and create a new one. A `moved` block updates the binding. See [6d](../../06-state/06d-drift-and-refactor).

**Performance.** Providers can refresh from the API, and they do on every plan. Cached attributes still matter: Terraform knows which objects to refresh, and large configurations avoid rediscovering the whole world from scratch.

**Collaboration.** Remote state plus locking lets a team share one mapping. See [6b](../../06-state/06b-locking) and [6c](../../06-state/06c-remote-backend).

## What state is not

State is not the desired configuration. The `.tf` files are. If they disagree, the next apply changes the real infrastructure to match the files (after refreshing).

State is not an encrypted secret store. Attribute values, including passwords assigned to ordinary arguments, are plaintext JSON. Treat the file like a credential.

State is not safe to edit by hand. Use `terraform state`, `moved`, `removed`, and `import`.

## Where it lives by default

With no `backend` block, Terraform uses the local backend and writes `terraform.tfstate` in the working directory. That is fine for this study repo. It is a bad fit for a team: the file is easy to commit, and two applies can race. Objective 6 is entirely about fixing that.

## A line from the official sample

"Usernames and passwords referenced in the Terraform code, even as variables, will end up in plain text in the state file."

That statement is true for normal values. Marking a variable `sensitive` changes display, not storage. The 1.12 mechanisms that do stay out of state are ephemeral values and write-only arguments, covered in [4h](../../04-configuration/04h-sensitive-data).

## Look at a real state file

After you apply [02c](../02c-multiple-providers) or [labs/local-stack](../../labs/local-stack):

```bash
terraform state list
terraform state show random_pet.primary
terraform show
```

Open `terraform.tfstate` once in an editor so the JSON is familiar, then leave it out of Git. The commands in [7b](../../07-maintain/07b-inspect-state) are the supported way to read it.
