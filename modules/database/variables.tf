variable "name_prefix" {
  type        = string
  description = "Prefix used for naming all resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for the DB subnet group"
}

variable "ecs_security_group_id" {
  type        = string
  description = "ECS security group ID to allow ingress from"
}

variable "engine" {
  type        = string
  default     = "postgres"
  description = "Database engine type (postgres, mysql, mariadb)"
}

variable "engine_version" {
  type        = string
  default     = "16"
  description = "Database engine version"
}

variable "instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "RDS instance class"
}

variable "allocated_storage" {
  type        = number
  default     = 20
  description = "Allocated storage in GB"
}

variable "storage_type" {
  type        = string
  default     = "gp3"
  description = "Storage type (gp2, gp3, io1, etc.)"
}

variable "db_name" {
  type        = string
  default     = "app"
  description = "Database name"
}

variable "username" {
  type        = string
  default     = "app"
  description = "Database master username"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Database master password"
}

variable "port" {
  type        = number
  default     = 5432
  description = "Database port"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "Whether the RDS instance is publicly accessible"
}

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Enable deletion protection on the RDS instance"
}

variable "backup_retention_period" {
  type        = number
  default     = 1
  description = "Backup retention period in days"
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Skip final snapshot when destroying"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
