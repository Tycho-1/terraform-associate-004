terraform {
  required_version = ">= 1.12.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "name" {
  type        = string
  description = "Short name written into every file."

  validation {
    condition     = length(var.name) > 2
    error_message = "Name must be longer than 2 characters."
  }
}

variable "regions" {
  type        = map(string)
  description = "CIDR per region. Each key becomes a file."
}

variable "revision" {
  type        = string
  description = "Bump this to replace terraform_data.token."
  default     = "1"
}

locals {
  label = "${var.name}-${terraform.workspace}"
}

resource "random_pet" "server" {
  length = 2
  prefix = local.label
}

resource "terraform_data" "token" {
  triggers_replace = var.revision

  lifecycle {
    create_before_destroy = true
  }
}

module "note" {
  source = "./modules/note"

  filename = "${path.module}/note.txt"
  body     = "pet=${random_pet.server.id} revision=${var.revision} token=${terraform_data.token.id}"
}

resource "local_file" "region" {
  for_each = var.regions

  filename = "${path.module}/${each.key}.txt"
  content  = "${local.label} ${each.value}\n"

  depends_on = [module.note]
}

check "has_a_region" {
  assert {
    condition     = length(var.regions) > 0
    error_message = "Set at least one region in terraform.tfvars."
  }
}

output "pet" {
  value = random_pet.server.id
}

output "note" {
  value = module.note.filename
}
