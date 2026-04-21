# New App Checklist

Use this checklist every time you create a new application from this template.

## Pre-deployment checklist

### Repository setup
- [ ] Created a new GitHub repository from the template
- [ ] Removed the template `.git` history and initialised a fresh repo
- [ ] Updated the app name in `frontend/index.html` (the `<title>` tag)
- [ ] Updated the brand label in `frontend/src/App.tsx`
- [ ] Ran `grep -r "REPLACE_ME" .` and replaced all placeholders
- [ ] Reviewed and updated `.gitignore` if the project adds new file types

### Terraform — dev environment
- [ ] Copied `infra/environments/dev/terraform.tfvars.example` to `terraform.tfvars`
- [ ] Set `project_name` (lowercase, short, no spaces or underscores — hyphens are fine)
- [ ] Set `github_org` and `github_repo`
- [ ] Configured S3 remote backend in `infra/environments/dev/backend.tf`
- [ ] Created the S3 state bucket and DynamoDB lock table
- [ ] Ran `terraform init` successfully
- [ ] Ran `terraform validate` with no errors
- [ ] Ran initial `terraform apply` (Step 1 of the two-step bootstrap)
- [ ] Noted `frontend_url` output
- [ ] Added the CloudFront URL to `cognito_callback_urls` in `terraform.tfvars`
- [ ] Ran second `terraform apply` to update Cognito

### Terraform — prod environment
- [ ] Copied `infra/environments/prod/terraform.tfvars.example` to `terraform.tfvars`
- [ ] Set `project_name`, `github_org`, `github_repo`
- [ ] Set `cognito_callback_urls` to the prod CloudFront URL (no localhost)
- [ ] Set `create_oidc_provider = false` (the provider was created by the dev apply)
- [ ] Configured S3 remote backend with a different key from dev
- [ ] Applied prod infrastructure

### Backend deployment
- [ ] Ran `npm install` in `backend/`
- [ ] Ran `npm run build:package` — confirmed `function.zip` produced
- [ ] Deployed the ZIP to the dev Lambda function
- [ ] Tested `/hello` endpoint returns 200
- [ ] (Optional) Enabled Bedrock model access — see `docs/bedrock-setup.md`
- [ ] (Optional) Tested `/bedrock-hello` endpoint

### Frontend deployment
- [ ] Ran `terraform output frontend_env_example` and copied values into `frontend/.env`
- [ ] Ran `npm install` in `frontend/`
- [ ] Ran `npm run build` — confirmed `dist/` produced with no errors
- [ ] Synced `dist/` to the S3 bucket
- [ ] Created CloudFront cache invalidation
- [ ] Opened the CloudFront URL in a browser — confirmed the app loads
- [ ] Clicked "Sign in" — confirmed redirect to Cognito Hosted UI
- [ ] Created a test user in the Cognito console and signed in
- [ ] Confirmed the `/hello` API call works after sign-in

### GitHub Actions
- [ ] Created `dev` and `prod` GitHub environments
- [ ] Added all required secrets to the `dev` environment (see `docs/github-oidc-setup.md`)
- [ ] Added all required variables to the `dev` environment
- [ ] Added all required secrets and variables to the `prod` environment
- [ ] Pushed a change to `backend/` — confirmed the `deploy-backend.yml` workflow runs
- [ ] Pushed a change to `frontend/` — confirmed the `deploy-frontend.yml` workflow runs
- [ ] Triggered `deploy-infra.yml` manually with `apply: false` — confirmed plan runs

### Security review
- [ ] Confirmed no `.env` files are committed to version control
- [ ] Confirmed no `terraform.tfvars` files are committed
- [ ] Confirmed no `function.zip` is committed
- [ ] Reviewed IAM role permissions — narrowed from `AdministratorAccess` if possible
- [ ] Confirmed `cors_allow_origins` is restricted to the actual frontend URL in prod
- [ ] Reviewed CloudWatch log retention settings

## Post-deployment

- [ ] Updated `docs/architecture.md` with any project-specific notes
- [ ] Added a CODEOWNERS file for the repository
- [ ] Shared the `frontend_url` output with the team

---

## Quick reference: Terraform outputs to GitHub secrets mapping

| Terraform output | GitHub secret/variable |
|-----------------|----------------------|
| `infra_deployer_role_arn` | `INFRA_ROLE_ARN_DEV` / `INFRA_ROLE_ARN_PROD` |
| `backend_deployer_role_arn` | `BACKEND_ROLE_ARN_DEV` / `BACKEND_ROLE_ARN_PROD` |
| `frontend_deployer_role_arn` | `FRONTEND_ROLE_ARN_DEV` / `FRONTEND_ROLE_ARN_PROD` |
| `api_url` | `VITE_API_URL_DEV` / `VITE_API_URL_PROD` |
| `cognito_user_pool_id` | `VITE_COGNITO_USER_POOL_ID_DEV` / `_PROD` |
| `cognito_client_id` | `VITE_COGNITO_CLIENT_ID_DEV` / `_PROD` |
| `cognito_hosted_ui_domain` | `VITE_COGNITO_HOSTED_UI_DOMAIN_DEV` / `_PROD` |
| `frontend_url` | `VITE_COGNITO_REDIRECT_URI_DEV` / `_PROD` |
| `frontend_bucket_name` | `S3_BUCKET_NAME_DEV` / `S3_BUCKET_NAME_PROD` (variable) |
| `cloudfront_distribution_id` | `CLOUDFRONT_DISTRIBUTION_ID_DEV` / `_PROD` (variable) |
| `lambda_function_name` | `LAMBDA_FUNCTION_NAME_DEV` / `_PROD` (variable) |
