data "aws_ecr_repository" "app" {
  name = local.project_name
}
