variable "project_name" {
  description = "Short project name, used in resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. dev, prod)."
  type        = string
}

variable "price_class" {
  description = "CloudFront price class.  Use PriceClass_100 (US/EU only) for lower cost during development."
  type        = string
  default     = "PriceClass_100"
}

variable "default_root_object" {
  description = "CloudFront default root object."
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
