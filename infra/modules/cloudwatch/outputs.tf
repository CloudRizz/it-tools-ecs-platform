# Exposes the CloudWatch log group name for use by the ECS task definition
output "log_group_name" {
  description = "Name of the ECS CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}