output "frontend_url" {
  description = "HTTPS URL of the CloudFront distribution (use this as the Cognito callback URL)."
  value       = module.frontend_hosting.frontend_url
}

output "api_url" {
  description = "Invoke URL for the API Gateway (set as VITE_API_URL in the frontend .env)."
  value       = module.api_gateway.api_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (set as VITE_COGNITO_USER_POOL_ID)."
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito App Client ID (set as VITE_COGNITO_CLIENT_ID)."
  value       = module.cognito.client_id
}

output "cognito_hosted_ui_domain" {
  description = "Cognito Hosted UI domain (set as VITE_COGNITO_HOSTED_UI_DOMAIN)."
  value       = module.cognito.hosted_ui_domain
}

output "region" {
  description = "AWS region."
  value       = var.aws_region
}

output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend assets."
  value       = module.frontend_hosting.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidation)."
  value       = module.frontend_hosting.distribution_id
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.lambda.function_name
}

output "infra_deployer_role_arn" {
  description = "IAM role ARN for the GitHub Actions infra deployer."
  value       = module.github_oidc_roles.infra_deployer_role_arn
}

output "backend_deployer_role_arn" {
  description = "IAM role ARN for the GitHub Actions backend deployer."
  value       = module.github_oidc_roles.backend_deployer_role_arn
}

output "frontend_deployer_role_arn" {
  description = "IAM role ARN for the GitHub Actions frontend deployer."
  value       = module.github_oidc_roles.frontend_deployer_role_arn
}

output "frontend_env_example" {
  description = "Example .env content for the frontend (copy into frontend/.env and fill VITE_COGNITO_REDIRECT_URI)."
  value       = <<-EOT
    VITE_API_URL=${module.api_gateway.api_url}
    VITE_COGNITO_REGION=${var.aws_region}
    VITE_COGNITO_USER_POOL_ID=${module.cognito.user_pool_id}
    VITE_COGNITO_CLIENT_ID=${module.cognito.client_id}
    VITE_COGNITO_HOSTED_UI_DOMAIN=${module.cognito.hosted_ui_domain}
    VITE_COGNITO_REDIRECT_URI=${module.frontend_hosting.frontend_url}
  EOT
}
