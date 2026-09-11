# Looks up the existing ECR repository containing the IT Tools image
data "aws_ecr_repository" "app" {
  name = var.project_name
}

# ECS cluster used to run the IT Tools Fargate service
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-cluster"
    }
  )
}

# Task definition describing how the IT Tools container should run
resource "aws_ecs_task_definition" "main" {
  family                   = var.project_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = var.execution_role_arn

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([
    {
      name  = var.project_name
      image = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"

      essential              = true
      readonlyRootFilesystem = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.project_name
        }
      }
    }
  ])
}

# ECS service keeps the IT Tools task running in the private subnets
resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn

  desired_count = var.desired_count
  launch_type   = "FARGATE"

  network_configuration {
    subnets = var.private_subnet_ids

    security_groups = [
      var.ecs_security_group_id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.project_name
    container_port   = 8080
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-service"
    }
  )
}