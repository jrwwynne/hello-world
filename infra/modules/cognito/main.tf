/**
 * Cognito Module
 *
 * Provisions a Cognito User Pool, an SPA app client using OAuth 2.0 PKCE,
 * and a Hosted UI domain.
 *
 * Outputs: user_pool_id, client_id, hosted_ui_domain
 */

data "aws_region" "current" {}

# ── User Pool ────────────────────────────────────────────────────────────────

resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-${var.environment}"

  # Users sign in with their e-mail address.
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = var.password_minimum_length
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Prevent user-enumeration attacks.
  user_pool_add_ons {
    advanced_security_mode = "OFF"
  }

  tags = var.tags
}

# ── App Client (SPA — no secret, PKCE only) ──────────────────────────────────

resource "aws_cognito_user_pool_client" "spa" {
  name         = "${var.project_name}-${var.environment}-spa"
  user_pool_id = aws_cognito_user_pool.this.id

  # Public client — no client secret (SPA cannot keep secrets).
  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Only allow refresh token flows; SRP and USER_PASSWORD_AUTH are disabled
  # because the hosted UI handles credential collection.
  explicit_auth_flows = ["ALLOW_REFRESH_TOKEN_AUTH"]

  prevent_user_existence_errors = "ENABLED"

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = 1
  id_token_validity      = 1
  refresh_token_validity = 30
}

# ── Hosted UI Domain ─────────────────────────────────────────────────────────
#
# The Cognito-managed sub-domain for the Hosted UI.
# Format: https://{domain}.auth.{region}.amazoncognito.com
#
# Note: domain names must be globally unique within a region.
# If "${project_name}-${environment}" is taken, set a custom domain_prefix
# variable or use a custom domain (Route 53 + ACM).

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.project_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.this.id
}
