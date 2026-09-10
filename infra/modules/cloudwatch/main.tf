# CloudWatch Log Group
# Stores stdout and stderr logs from ECS containers
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.retention_in_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-logs"
    }
  )
}