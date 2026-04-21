/**
 * Prod Environment Root Configuration
 *
 * Identical module composition to dev with production-appropriate settings:
 *   - CloudFront PriceClass_All (global edge locations)
 *   - OIDC provider creation defaults to false (shared with dev account)
 *   - Cognito callback URLs must be real production URLs (no localhost)
 */

locals {
  environment = "prod"
  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "terraform"
  }
}

module "frontend_hosting" {
  source = "../../modules/frontend_hosting"

  project_name = var.project_name
  environment  = local.environment
  price_class  = "PriceClass_All"
  tags         = local.common_tags
}

module "cognito" {
  source = "../../modules/cognito"

  project_name  = var.project_name
  environment   = local.environment
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls
  tags          = local.common_tags
}

module "lambda" {
  source = "../../modules/lambda"

  project_name       = var.project_name
  environment        = local.environment
  bedrock_model_id   = var.bedrock_model_id
  cors_allow_origin  = module.frontend_hosting.frontend_url
  log_retention_days = 30
  memory_size        = 512
  tags               = local.common_tags
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  project_name          = var.project_name
  environment           = local.environment
  lambda_invoke_arn     = module.lambda.invoke_arn
  lambda_function_name  = module.lambda.function_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.client_id
  cognito_issuer_url    = module.cognito.issuer_url
  cors_allow_origins    = [module.frontend_hosting.frontend_url]
  tags                  = local.common_tags
}

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
