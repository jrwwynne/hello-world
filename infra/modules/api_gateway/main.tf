/**
 * API Gateway Module (HTTP API v2)
 *
 * Provisions an AWS HTTP API with:
 *   - A JWT authoriser backed by Cognito
 *   - Lambda proxy integrations for GET /hello and GET /bedrock-hello
 *   - CORS configuration
 *   - A $default stage with auto-deploy
 *
 * Outputs: api_url
 */

# ── HTTP API ──────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-${var.environment}"
  protocol_type = "HTTP"
  description   = "${var.project_name} API — ${var.environment}"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }

  tags = var.tags
}

# ── JWT Authoriser (Cognito) ──────────────────────────────────────────────────

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = var.cognito_issuer_url
  }
}

# ── Lambda Integration ────────────────────────────────────────────────────────

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_invoke_arn
  payload_format_version = "2.0"
}

# ── Routes ────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_route" "hello" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /hello"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
  authorization_type = "JWT"
}

resource "aws_apigatewayv2_route" "bedrock_hello" {
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "GET /bedrock-hello"
  target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
  authorization_type = "JWT"
}

# ── Stage ─────────────────────────────────────────────────────────────────────

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      responseLength = "$context.responseLength"
      latency        = "$context.responseLatency"
      errorMessage   = "$context.error.message"
    })
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 14
  tags              = var.tags
}

# ── Lambda Permission ─────────────────────────────────────────────────────────
#
# Grants API Gateway permission to invoke the Lambda function.

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
