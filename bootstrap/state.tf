# Stores Terraform state remotely so GitHub Actions and local Terraform
# executions share the same infrastructure state.
resource "aws_s3_bucket" "terraform_state" {
  bucket        = var.terraform_state_bucket
  force_destroy = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-terraform-state"
    }
  )
}

# Keeps previous versions of the Terraform state file so accidental
# state changes or corruption can be recovered.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Prevents the Terraform state bucket from being exposed publicly.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enables server-side encryption for Terraform state stored in S3.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}