variable "project_name" {
  description = "Short project name, used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "handler" {
  description = "Lambda handler (filename.exportedFunction)."
  type        = string
  default     = "index.handler"
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "nodejs20.x"
}

variable "memory_size" {
  description = "Lambda memory allocation in MB."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda execution timeout in seconds."
  type        = number
  default     = 30
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 14
}

variable "environment_variables" {
  description = "Additional environment variables injected into the Lambda function."
  type        = map(string)
  default     = {}
}

variable "bedrock_model_id" {
  description = "Bedrock model ID the Lambda is permitted to invoke."
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "cors_allow_origin" {
  description = "Value of the CORS_ALLOW_ORIGIN environment variable."
  type        = string
  default     = "*"
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
