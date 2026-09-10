# Exposes the ALB security group ID for use by the ALB module
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# Exposes the ECS security group ID for use by the ECS module
output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

# Exposes the VPC endpoint security group ID
# for use by the VPC endpoints module
output "vpc_endpoint_security_group_id" {
  description = "ID of the VPC endpoint security group"
  value       = aws_security_group.vpc_endpoints.id
}