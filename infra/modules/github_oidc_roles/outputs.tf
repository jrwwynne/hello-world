output "infra_deployer_role_arn" {
  description = "ARN of the infra deployer IAM role."
  value       = aws_iam_role.infra_deployer.arn
}

output "backend_deployer_role_arn" {
  description = "ARN of the backend deployer IAM role."
  value       = aws_iam_role.backend_deployer.arn
}

output "frontend_deployer_role_arn" {
  description = "ARN of the frontend deployer IAM role."
  value       = aws_iam_role.frontend_deployer.arn
}
