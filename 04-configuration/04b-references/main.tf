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

variable "filename" {
  type    = string
  default = "unit.txt"
}

resource "random_pet" "server" {
  length = 2
}

resource "local_file" "unit" {
  filename = "${path.module}/${var.filename}"
  content  = random_pet.server.id
}

output "pet_id" {
  value = random_pet.server.id
}
