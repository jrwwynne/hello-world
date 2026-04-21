/**
 * Frontend Hosting Module
 *
 * Provisions a private S3 bucket and a CloudFront distribution with Origin
 * Access Control (OAC).  All public access to S3 is blocked; CloudFront is
 * the only entry point.
 *
 * SPA routing: CloudFront returns index.html for 404/403 errors so that
 * client-side routing works correctly on page refresh.
 *
 * Outputs: frontend_url, bucket_name, distribution_id
 */

data "aws_caller_identity" "current" {}

# ── S3 Bucket ─────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "frontend" {
  # Bucket names must be globally unique.  Using account ID ensures uniqueness
  # across multiple deployments of this template.
  bucket = "${var.project_name}-${var.environment}-frontend-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ── CloudFront Origin Access Control ─────────────────────────────────────────

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.project_name}-${var.environment}"
  description                       = "OAC for ${var.project_name} ${var.environment} frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ── CloudFront Distribution ───────────────────────────────────────────────────

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = var.default_root_object
  price_class         = var.price_class
  comment             = "${var.project_name} ${var.environment} frontend"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    # Cache for 1 hour by default.  Override for each file type using cache
    # invalidations after deployment.
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Return index.html for 403 and 404 so SPA client-side routing works.
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}

# ── S3 Bucket Policy (allow CloudFront OAC) ───────────────────────────────────

data "aws_iam_policy_document" "cloudfront_oac" {
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.cloudfront_oac.json

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
