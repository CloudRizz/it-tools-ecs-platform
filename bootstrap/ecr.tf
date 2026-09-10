# ECR repository - stores Docker images for the IT Tools application

resource "aws_ecr_repository" "app" {
  name                 = local.project_name
  image_tag_mutability = "IMMUTABLE" # Prevents overwriting existing image tags to ensure version control and traceability of Docker images
  force_delete         = true        # Allows the repository to be deleted even if it contains images, useful for cleanup during development or testing
  image_scanning_configuration {
    scan_on_push = true # Automatically scans images for vulnerabilities when pushed to the repository
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-ecr"
    }
  )
}