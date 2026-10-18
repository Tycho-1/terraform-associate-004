terraform {
  required_version = ">= 1.12.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "name" {
  type        = string
  description = "Short service name."
  default     = "api"

  validation {
    condition     = length(var.name) > 2 && length(var.name) < 16
    error_message = "Name must be between 3 and 15 characters."
  }
}

resource "terraform_data" "server" {
  input = var.name

  lifecycle {
    precondition {
      condition     = length(var.name) > 2
      error_message = "Name must be longer than 2 characters."
    }

    postcondition {
      condition     = self.output == var.name
      error_message = "Server data did not echo the requested name."
    }
  }
}

resource "local_file" "unit" {
  filename = "${path.module}/${var.name}.txt"
  content  = "${terraform_data.server.output}\n"

  lifecycle {
    postcondition {
      condition     = self.content != ""
      error_message = "The unit file was written empty."
    }
  }
}

# Fails with a warning when name != "api", but validation still allows other names.
check "demo_naming_policy" {
  assert {
    condition     = var.name == "api"
    error_message = "Demo check: this lab expects name=api. Validation still passed."
  }
}

output "name" {
  value = var.name

  precondition {
    condition     = startswith(var.name, "a") || startswith(var.name, "A")
    error_message = "This demo output only accepts a name that starts with A."
  }
}
