terraform {
  required_version = ">= 1.11.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

variable "api_token" {
  type        = string
  description = "Ordinary sensitive variable. Redacted on screen, stored in state if you use it in a managed attribute."
  sensitive   = true
  default     = "demo-token-not-a-real-secret"
}

ephemeral "random_password" "db" {
  length  = 20
  special = false
}

resource "terraform_data" "announce" {
  input = "db password generated for this run"

  # local-exec is an ephemeral context, so the password may be read here.
  # The command prints the length only. The password is not an attribute of this resource.
  provisioner "local-exec" {
    command = "echo ephemeral password length ${length(ephemeral.random_password.db.result)}"
  }
}

output "token_is_sensitive" {
  description = "Redacted by `terraform output`. Still present in state, because this output is not ephemeral."
  value       = var.api_token
  sensitive   = true
}
