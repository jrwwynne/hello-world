variable "project_name" {
  description = "Short project name, used in IAM role naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "github_org" {
  description = "GitHub organisation or user name that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)."
  type        = string
}

variable "create_oidc_provider" {
  description = <<-EOT
    Whether to create the GitHub Actions OIDC provider in this account.
    Only one OIDC provider per URL is allowed per account.  Set to false if
    the provider was already created by another Terraform configuration.
  EOT
  type        = bool
  default     = true
}

variable "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket (grants the frontend role S3 access)."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution (grants the frontend role invalidation access)."
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function (grants the backend role update access)."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
