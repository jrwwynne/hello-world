# Bedrock Setup Guide

## Overview

The platform template includes a `/bedrock-hello` endpoint that invokes an Amazon
Bedrock foundation model from the Lambda function.  Bedrock access is optional —
the `/hello` endpoint works without it.

## Prerequisites

Amazon Bedrock foundation models require explicit access enablement before they
can be invoked.  This is a one-time action per model per AWS account per region.

## Step 1 — Enable model access

1. Open the [Amazon Bedrock console](https://console.aws.amazon.com/bedrock/).
2. Ensure you are in the correct region (`ap-southeast-2` by default).
3. In the left sidebar, choose **Model access**.
4. Click **Modify model access**.
5. Find **Anthropic Claude 3 Haiku** (the default model) and tick the checkbox.
6. Click **Request model access** (or **Save changes** if the model is immediately available).

Some models are available immediately; others require a short review period.

## Step 2 — Verify access

Once access is granted, test the endpoint:

```bash
# Obtain an ID token from Cognito (sign in via the frontend and copy the token
# from sessionStorage in the browser developer tools)
ID_TOKEN="eyJ..."

API_URL=$(terraform -chdir=infra/environments/dev output -raw api_url)

curl -H "Authorization: Bearer $ID_TOKEN" "$API_URL/bedrock-hello"
```

Expected response:
```json
{
  "message": "Hello! I'm Claude, running on AWS Bedrock...",
  "modelId": "anthropic.claude-3-haiku-20240307-v1:0",
  "stopReason": "end_turn",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

## Changing the model

The model ID is configurable per environment.  Update `terraform.tfvars`:

```hcl
bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
```

Then run `terraform apply`.  The IAM policy and Lambda environment variable are
updated automatically.

### Available Claude models on Bedrock (as of early 2024)

| Model | ID |
|-------|-----|
| Claude 3 Haiku | `anthropic.claude-3-haiku-20240307-v1:0` |
| Claude 3 Sonnet | `anthropic.claude-3-sonnet-20240229-v1:0` |
| Claude 3 Opus | `anthropic.claude-3-opus-20240229-v1:0` |
| Claude 3.5 Sonnet | `anthropic.claude-3-5-sonnet-20240620-v1:0` |

Check the [Bedrock documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
for the current list of available model IDs.

## IAM permissions

The Lambda execution role is granted the following permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": "arn:aws:bedrock:{region}::foundation-model/{model_id}"
}
```

The resource is scoped to the specific model ID configured for the environment.
To permit all models, change the resource to `arn:aws:bedrock:*::foundation-model/*`
in `infra/modules/lambda/main.tf`.

## What is NOT included (yet)

- Bedrock Agents
- Bedrock Knowledge Bases
- Bedrock Guardrails
- Bedrock model fine-tuning

These can be added as additional Terraform modules when needed.

## Disabling Bedrock entirely

If you do not need Bedrock, you can safely ignore the `/bedrock-hello` route.
The `/hello` endpoint and all other infrastructure work without it.

To remove it completely:
1. Delete `backend/src/handlers/bedrockHello.ts` and its import in `backend/src/index.ts`.
2. Remove the `GET /bedrock-hello` route from `infra/modules/api_gateway/main.tf`.
3. Remove the `bedrock` IAM policy from `infra/modules/lambda/main.tf`.
