# Defines which AWS service is allowed to assume the ECS task execution role
data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Execution role used by ECS to pull container images and send logs
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.project_name}-ecs-task-execution-role"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-ecs-task-execution-role"
    }
  )
}
# Attach AWS-managed permissions required for ECR image pulls and CloudWatch logging
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

