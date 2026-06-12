output "cluster_id" {
  value       = aws_ecs_cluster.this.id
  description = "ECS cluster ID"
}

output "cluster_name" {
  value       = aws_ecs_cluster.this.name
  description = "ECS cluster name"
}

output "task_role_arn" {
  value       = aws_iam_role.task_role.arn
  description = "ECS task role ARN"
}

output "alb_dns_name" {
  value       = var.create_alb ? aws_lb.this[0].dns_name : null
  description = "ALB DNS name (if create_alb is true)"
}

output "alb_security_group_id" {
  value       = var.create_alb ? aws_security_group.alb[0].id : null
  description = "ALB security group ID"
}

output "endpoint" {
  value       = local.app_endpoint
  description = "Public endpoint (EIP if EC2+no ALB, ALB DNS otherwise)"
}

output "app_service_name" {
  value       = aws_ecs_service.app.name
  description = "ECS app service name"
}

output "app_task_definition_arn" {
  value       = aws_ecs_task_definition.app.arn
  description = "App task definition ARN"
}
