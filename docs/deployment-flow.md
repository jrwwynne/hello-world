# Deployment Flow

## Overview

Deployments flow through three separate pipelines, each with its own IAM role:

```
git push → GitHub Actions
             │
             ├── deploy-infra.yml    (infra-deployer role)   → Terraform
             ├── deploy-backend.yml  (backend-deployer role) → Lambda
             └── deploy-frontend.yml (frontend-deployer role)→ S3 + CloudFront
```

## First-time bootstrap (new environment)

The first deployment has a circular dependency: Cognito needs the CloudFront URL
as a callback URL, but CloudFront doesn't exist until Terraform runs.  Resolve
this with a two-step apply.

### Step 1 — Initial apply (infrastructure only)

```bash
cd infra/environments/dev

# Copy and fill in the tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — leave cognito_callback_urls as ["http://localhost:5173"]

terraform init
terraform apply
```

Note the `frontend_url` output:
```bash
terraform output frontend_url
# → https://d1234abcd.cloudfront.net
```

### Step 2 — Update Cognito callback URLs

Edit `terraform.tfvars` and add the CloudFront URL:

```hcl
cognito_callback_urls = [
  "http://localhost:5173",
  "https://d1234abcd.cloudfront.net",
]
cognito_logout_urls = [
  "http://localhost:5173",
  "https://d1234abcd.cloudfront.net",
]
```

Apply again:
```bash
terraform apply
```

### Step 3 — Build and deploy the Lambda

Terraform creates the Lambda function with a minimal placeholder handler on first apply.
The backend deploy workflow (or the commands below) replace it with the real code.

```bash
cd backend
npm install
npm run build:package

# Upload the real function code
aws lambda update-function-code \
  --function-name $(terraform -chdir=../infra/environments/dev output -raw lambda_function_name) \
  --zip-file fileb://function.zip
```

> **Why separate from Terraform?**  Terraform manages function _configuration_ (runtime, IAM role,
> environment variables, timeout).  Code updates happen independently via the CI/CD workflow.
> This means `terraform apply` never reverts a code deployment, and code deploys never require
> a full Terraform run.

### Step 4 — Build and deploy the frontend

Get the frontend environment values:
```bash
terraform -chdir=infra/environments/dev output frontend_env_example
```

Copy the output into `frontend/.env`, then:

```bash
cd frontend
npm install
npm run build

aws s3 sync dist/ s3://$(terraform -chdir=../infra/environments/dev output -raw frontend_bucket_name)/ --delete
aws cloudfront create-invalidation \
  --distribution-id $(terraform -chdir=../infra/environments/dev output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## Ongoing deployments (CI/CD)

After initial bootstrap, all deployments run via GitHub Actions:

| Trigger | Workflow | What it does |
|---------|----------|--------------|
| Push to `main` with changes in `infra/**` | deploy-infra.yml | Plans dev and prod (no auto-apply) |
| Push to `main` with changes in `backend/**` | deploy-backend.yml | Auto-deploys Lambda to dev |
| Push to `main` with changes in `frontend/**` | deploy-frontend.yml | Auto-deploys frontend to dev |
| Manual dispatch | Any workflow | Deploy to dev or prod with optional apply |

## Remote state setup

Before using CI/CD, configure an S3 remote backend for Terraform state:

1. Create an S3 bucket:
   ```bash
   aws s3 mb s3://your-project-terraform-state --region ap-southeast-2
   aws s3api put-bucket-versioning \
     --bucket your-project-terraform-state \
     --versioning-configuration Status=Enabled
   ```

2. Create a DynamoDB table for state locking:
   ```bash
   aws dynamodb create-table \
     --table-name your-project-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region ap-southeast-2
   ```

3. Uncomment the backend block in `infra/environments/{env}/backend.tf` and run:
   ```bash
   terraform init -migrate-state
   ```

## Environment promotion

To promote a change from dev to prod:

1. Merge to `main` (deploys to dev automatically)
2. Verify dev
3. Use the `workflow_dispatch` trigger to deploy to prod with `apply: true`

Production deployments always require a manual trigger.
