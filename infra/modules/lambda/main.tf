/**
 * Lambda Module
 *
 * Provisions the Lambda function, its IAM execution role (with Bedrock
 * permissions), and a CloudWatch log group.
 *
 * Deployment pattern:
 *   - Terraform creates the function with a minimal placeholder on first apply.
 *   - The backend CI/CD workflow calls `aws lambda update-function-code` to
 *     upload the real build artifact independently of Terraform.
 *   - `lifecycle.ignore_changes` prevents Terraform from reverting code updates
 *     made outside of Terraform.
 *
 * Outputs: function_arn, function_name, invoke_arn
 */

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# ── Placeholder Lambda package ────────────────────────────────────────────────
#
# Used only on the initial `terraform apply` when no real build artifact exists.
# The CI/CD backend deploy workflow replaces this with the real function.zip.

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  source {
    content  = <<-JS
      exports.handler = async () => ({
        statusCode: 200,
        body: JSON.stringify({ message: "Placeholder — run the backend deploy workflow to install the real function." }),
      });
    JS
    filename = "index.js"
  }
}

# ── IAM Execution Role ────────────────────────────────────────────────────────

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-${var.environment}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

# Basic execution: write logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Bedrock: allow model invocation for the configured model.
data "aws_iam_policy_document" "bedrock" {
  statement {
    sid    = "BedrockInvokeModel"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    # Permit the specific model configured for this environment.
    # To grant access to all models in the account, use:
    #   resources = ["arn:aws:bedrock:*::foundation-model/*"]
    resources = [
      "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.bedrock_model_id}",
    ]
  }
}

resource "aws_iam_role_policy" "bedrock" {
  name   = "bedrock-invoke"
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.bedrock.json
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ── Lambda Function ───────────────────────────────────────────────────────────

resource "aws_lambda_function" "this" {
  function_name = "${var.project_name}-${var.environment}"
  description   = "${var.project_name} backend — ${var.environment}"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.placeholder.output_path
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout

  source_code_hash = data.archive_file.placeholder.output_base64sha256

  environment {
    variables = merge(
      {
        BEDROCK_MODEL_ID  = var.bedrock_model_id
        CORS_ALLOW_ORIGIN = var.cors_allow_origin
        NODE_ENV          = var.environment
      },
      var.environment_variables,
    )
  }

  # Terraform manages function configuration (runtime, role, env vars, timeout).
  # Code updates are handled by the CI/CD backend deploy workflow.
  # Ignoring filename and source_code_hash prevents Terraform from reverting
  # to the placeholder after the real code has been deployed.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = var.tags
}
