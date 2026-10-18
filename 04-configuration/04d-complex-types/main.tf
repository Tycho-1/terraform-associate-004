terraform {
  required_version = ">= 1.12.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "regions" {
  description = "CIDR per region. The key is a map index, not a list index."
  type        = map(string)
  default = {
    eu-central-1 = "10.0.0.0/16"
    eu-west-1    = "10.1.0.0/16"
  }
}

variable "service" {
  type = object({
    name = string
    port = number
    tags = optional(map(string), {})
  })
  default = {
    name = "api"
    port = 443
  }
}

locals {
  primary_cidr = var.regions["eu-central-1"]
  label        = "${var.service.name}:${var.service.port}"
}

resource "local_file" "unit" {
  for_each = var.regions

  filename = "${path.module}/${each.key}.txt"
  content  = "${local.label}\n${each.value}\n"
}

output "primary_cidr" {
  value = local.primary_cidr
}
