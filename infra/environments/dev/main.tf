/**
 * Dev Environment Root Configuration
 *
 * Composes all platform modules into a complete dev deployment.
 *
 * Deployment order:
 *   1. First apply: provisions all resources with a placeholder Cognito
 *      callback URL (localhost only).
 *   2. Note the `frontend_url` output.
 *   3. Add the frontend_url to cognito_callback_urls in terraform.tfvars.
 *   4. Second apply: updates Cognito with the real callback URL.
 *
 * See docs/deployment-flow.md for the full walkthrough.
 */

locals {
  environment = "dev"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

# ── Frontend Hosting ──────────────────────────────────────────────────────────

module "frontend_hosting" {
  source = "../../modules/frontend_hosting"

  project_name = var.project_name
  environment  = local.environment
  price_class  = "PriceClass_100"
  tags         = local.common_tags
}

# ── Cognito ───────────────────────────────────────────────────────────────────

module "cognito" {
  source = "../../modules/cognito"

  project_name  = var.project_name
  environment   = local.environment
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls
  tags          = local.common_tags
}

# ── Lambda ────────────────────────────────────────────────────────────────────

module "lambda" {
  source = "../../modules/lambda"

  project_name      = var.project_name
  environment       = local.environment
  bedrock_model_id  = var.bedrock_model_id
  cors_allow_origin = module.frontend_hosting.frontend_url
  tags              = local.common_tags
}

# ── API Gateway ───────────────────────────────────────────────────────────────

module "api_gateway" {
  source = "../../modules/api_gateway"

  project_name          = var.project_name
  environment           = local.environment
  lambda_invoke_arn     = module.lambda.invoke_arn
  lambda_function_name  = module.lambda.function_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.client_id
  cognito_issuer_url    = module.cognito.issuer_url
  cors_allow_origins    = [module.frontend_hosting.frontend_url, "http://localhost:5173"]
  tags                  = local.common_tags
}

# ── GitHub OIDC Roles ─────────────────────────────────────────────────────────

module "github_oidc_roles" {
  source = "../../modules/github_oidc_roles"

  project_name                = var.project_name
  environment                 = local.environment
  github_org                  = var.github_org
  github_repo                 = var.github_repo
  create_oidc_provider        = var.create_oidc_provider
  frontend_bucket_arn         = module.frontend_hosting.bucket_arn
  cloudfront_distribution_arn = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${module.frontend_hosting.distribution_id}"
  lambda_function_arn         = module.lambda.function_arn
  tags                        = local.common_tags
}

data "aws_caller_identity" "current" {}
