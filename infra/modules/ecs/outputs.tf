# Exposes the ECS cluster name for root outputs and operational commands
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

# Exposes the ECS service name for operational commands
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}