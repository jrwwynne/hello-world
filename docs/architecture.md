# Architecture Overview

## System diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser                                                        │
│                                                                 │
│  React SPA (Vite + TypeScript)                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Cognito Hosted UI (PKCE)   API calls with ID token     │   │
│  └────────────┬───────────────────────────┬────────────────┘   │
└───────────────│───────────────────────────│────────────────────┘
                │                           │
                ▼                           ▼
┌───────────────────────────┐   ┌──────────────────────────────┐
│  Amazon Cognito           │   │  CloudFront (HTTPS)          │
│                           │   │  → S3 (private, OAC)         │
│  User Pool                │   │    Static frontend assets    │
│  App Client (PKCE)        │   └──────────────────────────────┘
│  Hosted UI domain         │
└───────────────────────────┘
                │  JWT authorisation
                ▼
┌───────────────────────────────────────────────────────────────┐
│  API Gateway (HTTP API v2)                                    │
│                                                               │
│  GET /hello          ──┐                                      │
│  GET /bedrock-hello  ──┤──► Lambda (Node.js 20)               │
│                         │                                      │
│  JWT authoriser         │   ┌──────────────────────────────┐  │
│  (Cognito pool)         └──►│  IAM execution role          │  │
└─────────────────────────────│  - CloudWatch logs           │  │
                               │  - Bedrock:InvokeModel       │  │
                               └──────────────────────────────┘  │
                                          │                       │
                                          ▼                       │
                               ┌──────────────────────────────┐  │
                               │  Amazon Bedrock               │  │
                               │  Claude 3 Haiku (configurable│  │
                               └──────────────────────────────┘
```

## Components

### Frontend
- **React 18 + Vite 5 + TypeScript** — minimal SPA starter
- **Cognito Hosted UI (OAuth 2.0 PKCE)** — no client secret in browser; hosted UI handles credential collection
- **CloudFront** — HTTPS, global CDN, serves assets from a private S3 bucket via Origin Access Control
- **S3** — stores compiled Vite build assets; all public access blocked

### Backend
- **AWS Lambda (Node.js 20)** — single function with an internal router; esbuild bundles TypeScript
- **API Gateway HTTP API v2** — lower cost and latency than REST API; JWT authoriser validates Cognito tokens
- **Amazon Bedrock** — Claude model invocation via AWS SDK v3; model ID configurable per environment

### Auth
- **Cognito User Pool** — email/password authentication; email verification
- **Hosted UI** — Cognito-managed sign-in page; handles MFA and password reset flows
- **PKCE flow** — authorisation code + code challenge; no client secret stored in the browser
- **JWT tokens** — ID token sent as `Authorization: Bearer <token>` header on API calls

### Infrastructure
- **Terraform** — all AWS resources managed as code; modular structure for reuse
- **GitHub Actions** — CI/CD with OIDC federation; no long-lived AWS credentials in GitHub

## Security boundaries

| Layer | Control |
|-------|---------|
| Frontend | CloudFront enforces HTTPS; S3 allows only CloudFront OAC |
| Auth | PKCE prevents code interception; Cognito validates credentials |
| API | JWT authoriser rejects calls without a valid Cognito token |
| Lambda | IAM execution role scoped to CloudWatch logs + specific Bedrock model |
| CI/CD | OIDC roles scoped to repository + GitHub environment; separate roles for infra/backend/frontend |
| Secrets | No hard-coded credentials; environment variables set via Terraform; CI secrets via GitHub |

## Region

All resources deploy to `ap-southeast-2` (Sydney) by default.  Override the `aws_region` variable to change this.

## Naming convention

Resources follow the pattern: `{project_name}-{environment}-{resource_type}`

Examples:
- `myapp-dev-lambda-exec` (IAM role)
- `myapp-dev` (Cognito User Pool, Lambda function)
- `myapp-dev-frontend-{account_id}` (S3 bucket, globally unique)
