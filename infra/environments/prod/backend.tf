# Remote State Configuration
#
# Uncomment and configure before using in CI/CD or team deployments.
# Use a separate state key from dev to keep environments fully isolated.

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_ME-terraform-state"
#     key            = "REPLACE_ME/prod/terraform.tfstate"
#     region         = "ap-southeast-2"
#     dynamodb_table = "REPLACE_ME-terraform-locks"
#     encrypt        = true
#   }
# }
