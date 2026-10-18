terraform {
  required_version = ">= 1.12.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "filename" {
  type        = string
  description = "File written next to this module."
  default     = "unit.txt"
}

variable "content" {
  type        = string
  description = "Body of the file."
  default     = "hello"
}

locals {
  path = "${path.module}/${var.filename}"
}

resource "local_file" "unit" {
  filename = local.path
  content  = "${var.content}\n"
}

output "path" {
  description = "File Terraform manages."
  value       = local_file.unit.filename
}

output "content" {
  description = "Body written to the file."
  value       = var.content
}
