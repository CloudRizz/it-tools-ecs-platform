# Stores the main infrastructure state remotely in S3 so local Terraform
# and GitHub Actions share the same source of truth.
terraform {
  backend "s3" {
    key          = "infra/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}