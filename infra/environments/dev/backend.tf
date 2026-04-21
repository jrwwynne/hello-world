# Remote State Configuration
#
# Uncomment and configure the S3 backend below before running Terraform in CI/CD
# or when collaborating with a team.
#
# Prerequisites:
#   1. Create an S3 bucket for state storage (e.g. my-project-terraform-state).
#   2. Create a DynamoDB table for state locking (partition key: LockID, type: String).
#   3. Update the values below to match your resources.
#   4. Run `terraform init` to migrate existing local state to S3.
#
# See docs/deployment-flow.md for full setup instructions.

# terraform {
#   backend "s3" {
#     bucket         = "REPLACE_ME-terraform-state"
#     key            = "REPLACE_ME/dev/terraform.tfstate"
#     region         = "ap-southeast-2"
#     dynamodb_table = "REPLACE_ME-terraform-locks"
#     encrypt        = true
#   }
# }
