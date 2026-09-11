# CloudWatch Log Group
# Stores stdout and stderr logs from ECS containers

resource "aws_cloudwatch_log_group" "ecs" {
  # checkov:skip=CKV_AWS_158:CloudWatch default encryption is accepted for this portfolio environment; a customer-managed KMS key would add unnecessary cost and complexity.
  # checkov:skip=CKV_AWS_338:Short log retention is intentional for this disposable portfolio environment to limit CloudWatch storage costs.
  name              = "/ecs/${var.project_name}"
  retention_in_days = var.retention_in_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-logs"
    }
  )
}