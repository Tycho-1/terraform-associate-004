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

variable "prefix" {
  type        = string
  description = "Prefix for the generated pet name."
}

variable "length" {
  type        = number
  description = "Number of words in the pet name."
  default     = 2
}

resource "random_pet" "this" {
  length = var.length
  prefix = var.prefix
}

resource "local_file" "unit" {
  filename = "${path.module}/${random_pet.this.id}.txt"
  content  = random_pet.this.id
}
