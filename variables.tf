# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------
variable "name_prefix" {
  type        = string
  default     = "myapp"
  description = "Prefix used for naming all resources"
}

variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "AWS region to deploy resources"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}

# ---------------------------------------------------------------------------
# Feature flags
# ---------------------------------------------------------------------------
variable "create_state" {
  type        = bool
  default     = true
  description = "Whether to create S3 backend + DynamoDB locking for Terraform state"
}

variable "create_state_locking_table" {
  type        = bool
  default     = true
  description = "Whether to create a DynamoDB table for state locking (~$0/mo)"
}

variable "create_vpc" {
  type        = bool
  default     = true
  description = "Whether to create a new VPC"
}

variable "create_ecs" {
  type        = bool
  default     = true
  description = "Whether to create ECS cluster and services"
}

variable "create_rds" {
  type        = bool
  default     = false
  description = "Whether to create an RDS database instance"
}

variable "create_delivery" {
  type        = bool
  default     = false
  description = "Whether to create CloudFront, Route53, S3 frontend, and CI/CD resources"
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for the VPC"
}

variable "az_count" {
  type        = number
  default     = 2
  description = "Number of availability zones to use"
}

variable "create_nat_gateway" {
  type        = bool
  default     = false
  description = "Whether to create a NAT Gateway for private subnets (adds ~$32/mo)"
}

variable "existing_vpc_id" {
  type        = string
  default     = ""
  description = "Existing VPC ID (required if create_vpc is false)"
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Existing public subnet IDs (required if create_vpc is false)"
}

variable "existing_private_subnet_ids" {
  type        = list(string)
  default     = []
  description = "Existing private subnet IDs (required if create_vpc is false and RDS is enabled)"
}

variable "existing_ecs_security_group_id" {
  type        = string
  default     = ""
  description = "Existing ECS security group ID (required if create_vpc is false)"
}

# ---------------------------------------------------------------------------
# Database (RDS)
# ---------------------------------------------------------------------------
variable "rds_engine" {
  type        = string
  default     = "postgres"
  description = "RDS engine (postgres, mysql, mariadb)"
}

variable "rds_engine_version" {
  type        = string
  default     = "16"
  description = "RDS engine version"
}

variable "rds_instance_class" {
  type        = string
  default     = "db.t4g.micro"
  description = "RDS instance class"
}

variable "rds_allocated_storage" {
  type        = number
  default     = 20
  description = "RDS allocated storage in GB"
}

variable "rds_storage_type" {
  type        = string
  default     = "gp3"
  description = "RDS storage type"
}

variable "rds_db_name" {
  type        = string
  default     = "app"
  description = "RDS database name"
}

variable "rds_username" {
  type        = string
  default     = "app"
  description = "RDS master username"
}

variable "rds_password" {
  type        = string
  sensitive   = true
  description = "RDS master password"
}

variable "rds_port" {
  type        = number
  default     = 5432
  description = "RDS port"
}

variable "rds_publicly_accessible" {
  type        = bool
  default     = false
  description = "Whether RDS is publicly accessible"
}

variable "rds_deletion_protection" {
  type        = bool
  default     = true
  description = "Enable RDS deletion protection"
}

variable "rds_backup_retention_period" {
  type        = number
  default     = 1
  description = "RDS backup retention in days"
}

variable "rds_skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Skip final snapshot on RDS destroy"
}

# ---------------------------------------------------------------------------
# Compute (ECS)
# ---------------------------------------------------------------------------
variable "launch_type" {
  type        = string
  default     = "EC2"
  description = "ECS launch type (EC2 or FARGATE)"

  validation {
    condition     = contains(["EC2", "FARGATE"], var.launch_type)
    error_message = "launch_type must be 'EC2' or 'FARGATE'."
  }
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for ECS (only for launch_type = EC2)"
}

variable "ecs_asg_min_size" {
  type        = number
  default     = 1
  description = "Minimum instances in the ECS auto scaling group"
}

variable "ecs_asg_max_size" {
  type        = number
  default     = 3
  description = "Maximum instances in the ECS auto scaling group"
}

variable "ecs_asg_desired_capacity" {
  type        = number
  default     = 1
  description = "Desired instances in the ECS auto scaling group"
}

variable "container_image" {
  type        = string
  description = "Docker image URL (e.g., <account>.dkr.ecr.<region>.amazonaws.com/<repo>)"
}

variable "container_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag to deploy"
}

variable "app_port" {
  type        = number
  default     = 8000
  description = "Container port the application listens on"
}

variable "container_cpu" {
  type        = number
  default     = 512
  description = "CPU units for the app task (1024 = 1 vCPU)"
}

variable "container_memory" {
  type        = number
  default     = 512
  description = "Memory in MiB for the app task"
}

variable "container_environment" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the app container"
}

variable "container_health_check" {
  type = object({
    command      = list(string)
    interval     = optional(number, 30)
    timeout      = optional(number, 5)
    retries      = optional(number, 3)
    start_period = optional(number, 120)
  })
  default = {
    command = ["CMD-SHELL", "curl -f http://localhost:8000/health/ || exit 1"]
  }
  description = "Health check configuration for the app container"
}

variable "create_alb" {
  type        = bool
  default     = false
  description = "Whether to create an Application Load Balancer"
}

variable "alb_health_check_path" {
  type        = string
  default     = "/health/"
  description = "Health check path for the ALB target group"
}

variable "create_worker" {
  type        = bool
  default     = false
  description = "Whether to create a background worker service"
}

variable "worker_container_environment" {
  type        = map(string)
  default     = {}
  description = "Environment variables for the worker container"
}

variable "worker_container_command" {
  type        = list(string)
  default     = null
  description = "Command override for the worker container"
}

variable "create_redis" {
  type        = bool
  default     = true
  description = "Whether to run a Redis container alongside the app"
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention in days"
}

variable "enable_container_insights" {
  type        = bool
  default     = false
  description = "Enable ECS Container Insights (adds ~$0.30/instance/month)"
}

variable "ecs_min_healthy_percent" {
  type        = number
  default     = 0
  description = "Minimum healthy percent during ECS deployment"
}

variable "ecs_max_percent" {
  type        = number
  default     = 100
  description = "Maximum percent during ECS deployment"
}

variable "enable_execute_command" {
  type        = bool
  default     = true
  description = "Enable ECS Exec for interactive command access"
}

# ---------------------------------------------------------------------------
# Delivery (CloudFront, Route53, S3, CI/CD)
# ---------------------------------------------------------------------------
variable "domain_name" {
  type        = string
  default     = ""
  description = "Domain name for Route53 and CloudFront (e.g., example.com)"
}

variable "create_route53_zone" {
  type        = bool
  default     = true
  description = "Whether to create a Route53 hosted zone"
}

variable "existing_zone_id" {
  type        = string
  default     = ""
  description = "Existing Route53 zone ID (if create_route53_zone is false)"
}

variable "acm_certificate_arn" {
  type        = string
  default     = ""
  description = "Existing ACM certificate ARN (if not creating one)"
}

variable "create_frontend_bucket" {
  type        = bool
  default     = true
  description = "Whether to create an S3 bucket for frontend hosting"
}

variable "frontend_bucket_name" {
  type        = string
  default     = ""
  description = "Override the frontend S3 bucket name (auto-generated from domain if empty)"
}

variable "s3_versioning_enabled" {
  type        = bool
  default     = true
  description = "Enable versioning on the frontend S3 bucket"
}

variable "s3_lifecycle_expiration_days" {
  type        = number
  default     = 90
  description = "Days after which to expire old noncurrent versions (0 to disable)"
}

variable "create_cloudfront_frontend" {
  type        = bool
  default     = true
  description = "Whether to create a CloudFront distribution for the frontend"
}

variable "create_cloudfront_api" {
  type        = bool
  default     = false
  description = "Whether to create a CloudFront distribution for the API"
}

variable "cloudfront_function_path" {
  type        = string
  default     = ""
  description = "Path to a custom CloudFront function JS (uses default SPA rewrite if empty)"
}

variable "cloudfront_price_class" {
  type        = string
  default     = "PriceClass_100"
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
}

variable "geo_restriction_type" {
  type        = string
  default     = "none"
  description = "CloudFront geo restriction (none, whitelist, blacklist)"
}

variable "geo_restriction_locations" {
  type        = list(string)
  default     = []
  description = "Country codes for geo restriction"
}

variable "create_ci_cd_user" {
  type        = bool
  default     = true
  description = "Whether to create an IAM user for CI/CD deployments"
}
