variable "project_name" {
  description = "Short name for the project (e.g. myapp).  Used in resource naming."
  type        = string
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "github_org" {
  description = "GitHub organisation or username that owns the repository."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)."
  type        = string
}

variable "create_oidc_provider" {
  description = "Set to false if the GitHub OIDC provider already exists in this account."
  type        = bool
  default     = false
}

variable "cognito_callback_urls" {
  description = "OAuth callback URLs for the Cognito app client."
  type        = list(string)
}

variable "cognito_logout_urls" {
  description = "Allowed sign-out redirect URLs for Cognito."
  type        = list(string)
}

variable "bedrock_model_id" {
  description = "Bedrock model ID the Lambda is permitted to invoke."
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

