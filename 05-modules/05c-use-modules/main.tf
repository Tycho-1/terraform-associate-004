terraform {
  required_version = ">= 1.12.0"
}

variable "prefix" {
  type    = string
  default = "web"
}

module "pet" {
  source = "./modules/pet"

  prefix = var.prefix
  length = 2
}

output "pet_name" {
  value = module.pet.name
}

output "filename" {
  value = module.pet.filename
}
