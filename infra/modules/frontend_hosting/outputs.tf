output "frontend_url" {
  description = "HTTPS URL of the CloudFront distribution."
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "cloudfront_domain" {
  description = "CloudFront domain name (without https://)."
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "distribution_id" {
  description = "CloudFront distribution ID (required for cache invalidation on deploy)."
  value       = aws_cloudfront_distribution.frontend.id
}

output "bucket_name" {
  description = "Name of the S3 bucket used for frontend assets."
  value       = aws_s3_bucket.frontend.id
}

output "bucket_arn" {
  description = "ARN of the frontend S3 bucket."
  value       = aws_s3_bucket.frontend.arn
}
