output "endpoint" {
  value       = aws_db_instance.this.address
  description = "RDS instance endpoint address"
}

output "port" {
  value       = aws_db_instance.this.port
  description = "RDS instance port"
}

output "db_name" {
  value       = aws_db_instance.this.db_name
  description = "Database name"
}

output "username" {
  value       = aws_db_instance.this.username
  description = "Database master username"
}

output "security_group_id" {
  value       = aws_security_group.rds.id
  description = "RDS security group ID"
}

output "arn" {
  value       = aws_db_instance.this.arn
  description = "RDS instance ARN"
}
