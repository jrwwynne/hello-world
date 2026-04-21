# GitHub OIDC Setup Guide

This guide explains how to configure GitHub Actions to authenticate with AWS using
OIDC federation.  No long-lived AWS access keys are stored in GitHub.

## How it works

1. GitHub Actions generates a short-lived OIDC token for each workflow run.
2. The workflow calls `sts:AssumeRoleWithWebIdentity` using that token.
3. AWS validates the token against the GitHub OIDC provider and issues temporary credentials.
4. The credentials expire when the workflow run ends.

## Prerequisites

- AWS account with permissions to create IAM roles and policies
- The Terraform `github_oidc_roles` module applied (creates the IAM roles automatically)
- A GitHub repository with Actions enabled

## Step 1 — Apply the Terraform OIDC module

The `github_oidc_roles` module creates:
- The GitHub OIDC provider in your AWS account (once per account)
- Three IAM roles: `infra-deployer`, `backend-deployer`, `frontend-deployer`

```bash
# During initial bootstrap, the roles are created as part of the full apply.
terraform -chdir=infra/environments/dev apply

# Retrieve the role ARNs:
terraform -chdir=infra/environments/dev output infra_deployer_role_arn
terraform -chdir=infra/environments/dev output backend_deployer_role_arn
terraform -chdir=infra/environments/dev output frontend_deployer_role_arn
```

## Step 2 — Create GitHub environments

In your GitHub repository settings, create two environments:

1. `dev`
2. `prod`

Optionally, add protection rules to the `prod` environment (e.g. required reviewers).

## Step 3 — Add secrets and variables to each GitHub environment

### dev environment

**Secrets** (Settings → Environments → dev → Environment secrets):

| Secret name | Value |
|------------|-------|
| `INFRA_ROLE_ARN_DEV` | ARN from `terraform output infra_deployer_role_arn` |
| `BACKEND_ROLE_ARN_DEV` | ARN from `terraform output backend_deployer_role_arn` |
| `FRONTEND_ROLE_ARN_DEV` | ARN from `terraform output frontend_deployer_role_arn` |
| `VITE_API_URL_DEV` | Value from `terraform output api_url` |
| `VITE_COGNITO_USER_POOL_ID_DEV` | Value from `terraform output cognito_user_pool_id` |
| `VITE_COGNITO_CLIENT_ID_DEV` | Value from `terraform output cognito_client_id` |
| `VITE_COGNITO_HOSTED_UI_DOMAIN_DEV` | Value from `terraform output cognito_hosted_ui_domain` |
| `VITE_COGNITO_REDIRECT_URI_DEV` | Value from `terraform output frontend_url` |

**Variables** (Settings → Environments → dev → Environment variables):

| Variable name | Value |
|--------------|-------|
| `S3_BUCKET_NAME_DEV` | Value from `terraform output frontend_bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID_DEV` | Value from `terraform output cloudfront_distribution_id` |
| `LAMBDA_FUNCTION_NAME_DEV` | Value from `terraform output lambda_function_name` |

### prod environment

Repeat the same configuration for the `prod` environment, using values from:
```bash
terraform -chdir=infra/environments/prod output ...
```

> **Note:** `INFRA_ROLE_ARN` secrets are set at the repository level in `deploy-infra.yml`
> (as `INFRA_ROLE_ARN_DEV` / `INFRA_ROLE_ARN_PROD`) rather than per-environment, because
> the infra workflow needs to reference both environments in a single workflow file.
> You can move them to environment-level secrets if you split the infra workflow.

## Step 4 — Verify the OIDC trust policy

The trust policy on each IAM role restricts which GitHub Actions jobs can assume it:

```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:environment:dev"
    }
  }
}
```

The `sub` claim ties role assumption to:
- A specific repository (`OWNER/REPO`)
- A specific GitHub environment (`dev` or `prod`)

Jobs not associated with that environment cannot assume the role.

## Troubleshooting

**Error: `Could not assume role with OIDC`**
- Verify the role ARN in the GitHub secret matches the IAM role exactly.
- Check the trust policy `sub` condition matches the repository and environment name.
- Ensure the workflow has `permissions: id-token: write`.

**Error: `AccessDenied` on AWS API calls**
- The role was assumed but lacks the required permissions.
- Check the IAM role's inline policy for the specific API action.

**OIDC provider already exists**
- If another project created the OIDC provider first, set `create_oidc_provider = false`
  in `terraform.tfvars` to skip creating it again.
