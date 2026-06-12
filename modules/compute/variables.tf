variable "name_prefix" {
  type        = string
  description = "Prefix used for naming all resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "ecs_security_group_id" {
  type        = string
  description = "ECS security group ID"
}

variable "az_names" {
  type        = list(string)
  description = "List of availability zone names"
}

variable "ecs_ami_id" {
  type        = string
  description = "ECS-optimized AMI ID"
  default     = null
}

variable "launch_type" {
  type        = string
  default     = "EC2"
  description = "ECS launch type (EC2 or FARGATE)"

  validation {
    condition     = contains(["EC2", "FARGATE"], var.launch_type)
    error_message = "launch_type must be either 'EC2' or 'FARGATE'."
  }
}

variable "ec2_instance_type" {
  type        = string
  default     = "t3.micro"
  description = "EC2 instance type for ECS container instances"
}

variable "ecs_asg_min_size" {
  type        = number
  default     = 1
  description = "Minimum size of the ECS auto scaling group"
}

variable "ecs_asg_max_size" {
  type        = number
  default     = 3
  description = "Maximum size of the ECS auto scaling group"
}

variable "ecs_asg_desired_capacity" {
  type        = number
  default     = 1
  description = "Desired capacity of the ECS auto scaling group"
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
    command     = list(string)
    interval    = optional(number, 30)
    timeout     = optional(number, 5)
    retries     = optional(number, 3)
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
  description = "Whether to create a worker (Celery/Sidekiq/etc.) service"
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

variable "database_endpoint" {
  type        = string
  default     = ""
  description = "RDS endpoint (injected as DB_HOST env var)"
}

variable "database_port" {
  type        = string
  default     = ""
  description = "RDS port (injected as DB_PORT env var)"
}

variable "log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention in days"
}

variable "enable_container_insights" {
  type        = bool
  default     = false
  description = "Enable ECS container Insights (adds ~$0.30/instance/month)"
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

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
