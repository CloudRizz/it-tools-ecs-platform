# Outputs the generated S3 bucket name so it can be configured
# as the remote backend for the main Terraform infrastructure.
output "terraform_state_bucket" {
  description = "S3 bucket used to store the main Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}

# IAM role GitHub Actions assumes through OIDC to deploy resources to AWS
output "github_actions_role_arn" {
  description = "IAM role assumed by GitHub Actions through OIDC"
  value       = aws_iam_role.github_actions.arn
}

# ECR repository where the CI/CD pipeline pushes application Docker images
output "ecr_repository_url" {
  description = "ECR repository URL used by the deployment pipeline"
  value       = aws_ecr_repository.app.repository_url
}