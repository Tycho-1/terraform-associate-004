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

variable "content" {
  type        = string
  description = "Body of the generated file."
  default     = "web"
}

resource "random_pet" "server" {
  length = 2
}

resource "local_file" "unit" {
  filename = "${path.module}/unit.txt"
  content  = "${random_pet.server.id}\n${var.content}\n"
}

output "filename" {
  value = local_file.unit.filename
}
