output "user_pool_id" {
  description = "ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool."
  value       = aws_cognito_user_pool.this.arn
}

output "client_id" {
  description = "ID of the SPA app client."
  value       = aws_cognito_user_pool_client.spa.id
}

output "hosted_ui_domain" {
  description = "Cognito Hosted UI domain (without https://)."
  value       = "${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

output "issuer_url" {
  description = "JWT issuer URL used by API Gateway for token validation."
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}
