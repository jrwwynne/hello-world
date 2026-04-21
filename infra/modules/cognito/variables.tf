variable "project_name" {
  description = "Short name for the project, used in resource naming (e.g. myapp)."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "callback_urls" {
  description = "List of allowed OAuth callback URLs for the app client."
  type        = list(string)
}

variable "logout_urls" {
  description = "List of allowed sign-out URLs for the app client."
  type        = list(string)
}

variable "password_minimum_length" {
  description = "Minimum password length for the user pool."
  type        = number
  default     = 8
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
