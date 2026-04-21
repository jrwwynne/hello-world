/**
 * GitHub OIDC Roles Module
 *
 * Provisions three IAM roles for GitHub Actions deployments using OIDC
 * federation.  No long-lived AWS credentials are stored in GitHub.
 *
 * Roles created:
 *   - infra-deployer   — runs Terraform (broad AWS access; restrict per project)
 *   - backend-deployer — updates the Lambda function code
 *   - frontend-deployer — syncs S3 and invalidates CloudFront
 *
 * Trust policies restrict role assumption to GitHub Actions jobs in the
 * specified repository and environment.
 *
 * See docs/github-oidc-setup.md for setup instructions.
 */

data "aws_caller_identity" "current" {}

locals {
  oidc_provider_url = "token.actions.githubusercontent.com"
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
  repo_subject      = "repo:${var.github_org}/${var.github_repo}:environment:${var.environment}"
}

# ── OIDC Provider ─────────────────────────────────────────────────────────────
#
# One OIDC provider per account is shared across all GitHub Actions workflows.
# Set create_oidc_provider = false in subsequent environments that share the
# same AWS account.

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://${local.oidc_provider_url}"
  client_id_list  = ["sts.amazonaws.com"]
  # The thumbprint is not used for verification by AWS (it trusts the OIDC
  # provider's certificate directly), but the field is required by Terraform.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

# ── Trust Policy (shared template) ───────────────────────────────────────────

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "${local.oidc_provider_url}:sub"
      values   = [local.repo_subject]
    }
  }
}

# ── Infra Deployer Role ───────────────────────────────────────────────────────
#
# Runs Terraform plan and apply.  Requires broad AWS permissions to manage the
# resources defined in the Terraform modules.
#
# NOTE: AdministratorAccess is used here for template simplicity.  For
# production deployments, restrict to only the services your Terraform manages.

resource "aws_iam_role" "infra_deployer" {
  name               = "${var.project_name}-${var.environment}-infra-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
  description        = "GitHub Actions infra deployer for ${var.project_name} ${var.environment}"
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "infra_admin" {
  role       = aws_iam_role.infra_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ── Backend Deployer Role ─────────────────────────────────────────────────────
#
# Updates the Lambda function code.  Scoped to the specific Lambda function.

resource "aws_iam_role" "backend_deployer" {
  name               = "${var.project_name}-${var.environment}-backend-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
  description        = "GitHub Actions backend deployer for ${var.project_name} ${var.environment}"
  tags               = var.tags
}

data "aws_iam_policy_document" "backend_deployer" {
  statement {
    sid    = "UpdateLambdaCode"
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:PublishVersion",
    ]
    resources = [var.lambda_function_arn]
  }
}

resource "aws_iam_role_policy" "backend_deployer" {
  name   = "backend-deployer-policy"
  role   = aws_iam_role.backend_deployer.id
  policy = data.aws_iam_policy_document.backend_deployer.json
}

# ── Frontend Deployer Role ────────────────────────────────────────────────────
#
# Syncs built assets to S3 and creates a CloudFront cache invalidation.

resource "aws_iam_role" "frontend_deployer" {
  name               = "${var.project_name}-${var.environment}-frontend-deployer"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
  description        = "GitHub Actions frontend deployer for ${var.project_name} ${var.environment}"
  tags               = var.tags
}

data "aws_iam_policy_document" "frontend_deployer" {
  statement {
    sid    = "S3SyncAssets"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      var.frontend_bucket_arn,
      "${var.frontend_bucket_arn}/*",
    ]
  }

  statement {
    sid    = "CloudFrontInvalidate"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
    ]
    resources = [var.cloudfront_distribution_arn]
  }
}

resource "aws_iam_role_policy" "frontend_deployer" {
  name   = "frontend-deployer-policy"
  role   = aws_iam_role.frontend_deployer.id
  policy = data.aws_iam_policy_document.frontend_deployer.json
}
