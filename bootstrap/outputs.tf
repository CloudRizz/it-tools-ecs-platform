# Outputs the generated S3 bucket name so it can be configured
# as the remote backend for the main Terraform infrastructure.
output "terraform_state_bucket" {
  description = "S3 bucket used to store the main Terraform remote state"
  value       = aws_s3_bucket.terraform_state.bucket
}
