terraform {
  required_version = ">= 1.12.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "unit" {
  filename = "${path.module}/unit.txt"
  content  = "hello from a managed resource\n"
}

data "local_file" "unit" {
  filename = local_file.unit.filename
}

output "read_back" {
  value = data.local_file.unit.content
}
