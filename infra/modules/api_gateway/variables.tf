variable "project_name" {
  description = "Short project name, used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function to integrate with."
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function (required for the resource-based permission)."
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool used for JWT authorisation."
  type        = string
}

variable "cognito_client_id" {
  description = "Cognito app client ID added to the JWT authoriser audience list."
  type        = string
}

variable "cognito_issuer_url" {
  description = "JWT issuer URL (e.g. https://cognito-idp.{region}.amazonaws.com/{pool_id})."
  type        = string
}

variable "cors_allow_origins" {
  description = "Allowed CORS origins for the API.  Use [\"*\"] for local development."
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
