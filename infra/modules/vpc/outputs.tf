# Exposes the VPC ID so other modules can deploy resources into this VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

# Exposes both public subnet IDs for resources that need internet-facing connectivity,
# such as the Application Load Balancer
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

# Exposes both private subnet IDs so ECS Fargate tasks and VPC endpoints
# can be deployed privately across both Availability Zones
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
}

# Exposes the public route table ID for resources that need to reference
# the routing configuration of the public subnets
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# Exposes the private route table ID so private services such as the
# S3 Gateway Endpoint can use the private subnet routing configuration
output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}