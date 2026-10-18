terraform {
  required_version = ">= 1.12.0"
}

variable "revision" {
  type        = string
  description = "Changing this replaces terraform_data.server."
  default     = "1"
}

resource "terraform_data" "server" {
  triggers_replace = {
    revision = var.revision
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "terraform_data" "service" {
  depends_on = [terraform_data.server]

  input = "ready"
}

output "server_id" {
  value = terraform_data.server.id
}
