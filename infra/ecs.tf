# ECS cluster used to run the IT Tools Fargate service
resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-cluster"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-cluster"
    }
  )
}

# Task definition describing how the IT Tools container should run
resource "aws_ecs_task_definition" "main" {
  family                   = local.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = local.project_name
      image = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"

      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      log_configuration = {
        log_Driver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = local.project_name
        }
      }
    }
  ])
}

# ECS service keeps the IT Tools task running in the private subnets
resource "aws_ecs_service" "app" {
  name            = "${local.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.project_name
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.https
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-service"
    }
  )
}