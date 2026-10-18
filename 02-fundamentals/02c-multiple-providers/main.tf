terraform {
  required_version = ">= 1.12.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "random" {}

provider "random" {
  alias = "backup"
}

resource "random_pet" "primary" {
  length = 2
}

resource "random_pet" "backup" {
  provider = random.backup
  length   = 2
}

resource "local_file" "names" {
  filename = "${path.module}/names.txt"
  content  = "primary=${random_pet.primary.id}\nbackup=${random_pet.backup.id}\n"
}
