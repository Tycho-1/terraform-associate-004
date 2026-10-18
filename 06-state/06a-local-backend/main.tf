terraform {
  required_version = ">= 1.12.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

resource "random_pet" "server" {
  length = 2
  prefix = terraform.workspace
}

output "workspace" {
  value = terraform.workspace
}
