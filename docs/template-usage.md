# Template Usage Guide

## What this repository is

This is a reusable platform template for deploying web applications on AWS.
It provides a complete, production-minded starting point covering:

- React frontend (Vite + TypeScript)
- Lambda backend (Node.js 20 + TypeScript)
- Terraform infrastructure modules
- GitHub Actions CI/CD with OIDC
- Amazon Cognito authentication
- Amazon Bedrock connectivity

## How to use this template for a new project

### 1. Create a new repository from the template

Use the GitHub "Use this template" button, or clone and reinitialise:

```bash
git clone https://github.com/YOUR_ORG/aws-platform-template.git my-new-app
cd my-new-app
rm -rf .git
git init
git add .
git commit -m "Initial commit from platform template"
```

### 2. Find and replace the placeholder values

All customisable values use a consistent placeholder: `REPLACE_ME`.

Run this to find every location:
```bash
grep -r "REPLACE_ME" .
```

Key values to replace:

| Placeholder | Replace with | Found in |
|-------------|-------------|----------|
| `REPLACE_ME` (project_name) | Your project short name (lowercase, no spaces) | `terraform.tfvars.example` files |
| `REPLACE_ME` (github_org) | Your GitHub org/user | `terraform.tfvars.example` files |
| `REPLACE_ME` (github_repo) | Your GitHub repo name | `terraform.tfvars.example` files |
| `Platform App` | Your app name | `frontend/index.html`, `frontend/src/App.tsx` |

### 3. Configure Terraform

```bash
# Dev
cp infra/environments/dev/terraform.tfvars.example infra/environments/dev/terraform.tfvars
# Edit the file and set project_name, github_org, github_repo

# Prod
cp infra/environments/prod/terraform.tfvars.example infra/environments/prod/terraform.tfvars
# Edit similarly
```

### 4. Follow the deployment flow

See [deployment-flow.md](./deployment-flow.md) for the full step-by-step process.

### 5. Configure GitHub Actions

See [github-oidc-setup.md](./github-oidc-setup.md) for setting up the GitHub
environments, secrets, and variables required for CI/CD.

---

## Customisation reference

### Replacing the frontend

The frontend lives entirely in `frontend/`.  Replace it at will:

1. Delete `frontend/src/` and replace with your application code.
2. Keep `frontend/.env.example` updated with any new environment variables.
3. Ensure `npm run build` produces output in `frontend/dist/`.
4. The S3 + CloudFront hosting and the CI/CD workflow do not change.

### Replacing the backend

The backend lives entirely in `backend/src/`.  Replace it at will:

1. Replace or extend the handlers in `backend/src/handlers/`.
2. Add new routes to `backend/src/index.ts` (the router).
3. Add corresponding routes in `infra/modules/api_gateway/main.tf`.
4. Ensure `npm run build:package` produces `backend/function.zip`.
5. The Lambda, IAM role, and CI/CD workflow do not change.

### Adding a new Lambda route

1. Create `backend/src/handlers/myRoute.ts`.
2. Add the case to the router in `backend/src/index.ts`.
3. In `infra/modules/api_gateway/main.tf`, add:
   ```hcl
   resource "aws_apigatewayv2_route" "my_route" {
     api_id             = aws_apigatewayv2_api.this.id
     route_key          = "GET /my-route"
     target             = "integrations/${aws_apigatewayv2_integration.lambda.id}"
     authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
     authorization_type = "JWT"
   }
   ```
4. Run `terraform apply` in the relevant environment.

### Changing the AWS region

Update `aws_region` in `terraform.tfvars` for each environment.  The Cognito
hosted UI domain, CloudFront, and all other resources follow automatically.

### Adding a custom domain

1. Create an ACM certificate in `us-east-1` (required for CloudFront).
2. Add `aliases` and `viewer_certificate` to the CloudFront resource in
   `infra/modules/frontend_hosting/main.tf`.
3. Add a Route 53 alias record pointing to the CloudFront distribution.
4. Update `cognito_callback_urls` to use the custom domain.
5. Update `VITE_COGNITO_REDIRECT_URI` in GitHub secrets to the custom domain.

### Supporting a third environment (e.g. staging)

1. Copy `infra/environments/dev/` to `infra/environments/staging/`.
2. Update the `local.environment` value to `"staging"`.
3. Create a `staging` GitHub environment and add the required secrets/variables.
4. Add a `staging` case to the workflow dispatch inputs in the workflow files.

### Using a different Bedrock model

Update `bedrock_model_id` in `terraform.tfvars` and run `terraform apply`.
Remember to enable model access in the Bedrock console.
See [bedrock-setup.md](./bedrock-setup.md).

---

## What stays the same across all projects

- Terraform module structure (`infra/modules/`)
- CI/CD reusable workflows (`.github/workflows/_reusable-*.yml`)
- Composite actions (`.github/actions/`)
- IAM role naming conventions
- The OIDC federation pattern
- S3 + CloudFront hosting pattern
- Cognito + JWT authorisation pattern

These are the reusable patterns.  Only the application code inside `frontend/src/`
and `backend/src/` needs to change between projects.
