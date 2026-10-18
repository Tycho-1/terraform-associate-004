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

variable "names" {
  type    = list(string)
  default = ["web", "api", "db"]
}

variable "regions" {
  type = map(string)
  default = {
    eu-central-1 = "10.0.0.0/16"
    eu-west-1    = "10.1.0.0/16"
  }
}

locals {
  upper_names = [for name in var.names : upper(name) if length(name) > 1]

  primary = lookup(var.regions, "eu-central-1", "0.0.0.0/0")

  rendered = templatefile("${path.module}/unit.tftpl", {
    names   = local.upper_names
    primary = local.primary
  })
}

resource "random_pet" "named" {
  for_each = toset(var.names)

  length = 1
  prefix = each.value
}

resource "local_file" "unit" {
  filename = "${path.module}/rendered.txt"
  content  = local.rendered
}

output "pet_ids" {
  value = { for key, pet in random_pet.named : key => pet.id }
}
