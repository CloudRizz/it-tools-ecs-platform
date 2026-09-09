# CloudWatch Log Group - stores stdout/stderr logs from ECS containers

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.project_name}"
  retention_in_days = 7 # Retain logs for 7 days to manage storage costs while keeping recent logs for troubleshooting

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-logs"
    }
  )
}

