terraform {
  required_version = ">= 1.12.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Step 1: apply this file as-is.
# Step 2: rename the resource to "renamed", uncomment the moved block, plan.
# The plan should say the resource has moved, and the pet name should stay.

resource "random_pet" "server" {
  length = 2
}

# moved {
#   from = random_pet.server
#   to   = random_pet.renamed
# }

# Dropping a resource from the configuration destroys it.
# Uncomment this only after you have removed a resource block and you want
# Terraform to forget the object instead of deleting it.
#
# removed {
#   from = random_pet.server
#
#   lifecycle {
#     destroy = false
#   }
# }
