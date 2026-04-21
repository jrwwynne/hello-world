output "api_url" {
  description = "Invoke URL for the API Gateway $default stage."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  description = "ID of the HTTP API."
  value       = aws_apigatewayv2_api.this.id
}

output "execution_arn" {
  description = "Execution ARN of the HTTP API (used for Lambda permissions)."
  value       = aws_apigatewayv2_api.this.execution_arn
}
