# Bootstrap Infrastructure

This directory contains the foundational AWS resources required **before** the main IT Tools infrastructure can be deployed through GitHub Actions.

## Why Bootstrap Exists

The main Terraform deployment depends on resources that must already exist:

- **S3 state bucket** – stores the remote Terraform state for `infra/`.
- **GitHub OIDC provider** – allows GitHub Actions to authenticate to AWS without storing long-lived AWS access keys.
- **GitHub Actions IAM role and policy** – provides the AWS permissions required by the deployment pipeline.
- **ECR repository** – stores the Docker images built and pushed by GitHub Actions.

This avoids a circular dependency where GitHub Actions would need AWS infrastructure in order to create the infrastructure it depends on.

## Deployment Flow

```text
Local Terraform
      │
      ▼
 bootstrap/
      │
      ├── S3 Terraform State
      ├── GitHub OIDC
      ├── GitHub Actions IAM Role
      └── ECR Repository
              │
              ▼
       GitHub Actions
              │
              ▼
           infra/
              │
              ▼
     ECS Application Stack