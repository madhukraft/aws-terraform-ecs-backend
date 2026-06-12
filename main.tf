locals {
  vpc_id               = var.create_vpc ? module.vpc[0].vpc_id : var.existing_vpc_id
  public_subnet_ids    = var.create_vpc ? module.vpc[0].public_subnet_ids : var.existing_public_subnet_ids
  private_subnet_ids   = var.create_vpc ? module.vpc[0].private_subnet_ids : var.existing_private_subnet_ids
  ecs_security_group_id = var.create_vpc ? module.vpc[0].ecs_security_group_id : var.existing_ecs_security_group_id
}

module "state" {
  source = "./modules/state"
  count   = var.create_state ? 1 : 0

  name_prefix          = var.name_prefix
  account_id           = local.account_id
  create_locking_table = var.create_state_locking_table
}

module "vpc" {
  source = "./modules/vpc"
  count   = var.create_vpc ? 1 : 0

  name_prefix        = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  az_names           = local.az_names
  create_nat_gateway = var.create_nat_gateway
  tags               = var.tags
}

module "database" {
  source = "./modules/database"
  count   = var.create_rds ? 1 : 0

  name_prefix           = var.name_prefix
  vpc_id                = local.vpc_id
  private_subnet_ids    = local.private_subnet_ids
  ecs_security_group_id = local.ecs_security_group_id
  engine                = var.rds_engine
  engine_version        = var.rds_engine_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  storage_type          = var.rds_storage_type
  db_name               = var.rds_db_name
  username              = var.rds_username
  password              = var.rds_password
  port                  = var.rds_port
  publicly_accessible   = var.rds_publicly_accessible
  deletion_protection   = var.rds_deletion_protection
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot   = var.rds_skip_final_snapshot
  tags                  = var.tags
}

module "compute" {
  source = "./modules/compute"
  count   = var.create_ecs ? 1 : 0

  name_prefix          = var.name_prefix
  vpc_id               = local.vpc_id
  public_subnet_ids    = local.public_subnet_ids
  ecs_security_group_id = local.ecs_security_group_id
  az_names             = local.az_names
  ecs_ami_id           = local.ecs_ami_id
  launch_type          = var.launch_type
  ec2_instance_type    = var.ec2_instance_type
  ecs_asg_min_size     = var.ecs_asg_min_size
  ecs_asg_max_size     = var.ecs_asg_max_size
  ecs_asg_desired_capacity = var.ecs_asg_desired_capacity
  container_image      = var.container_image
  container_tag        = var.container_tag
  app_port             = var.app_port
  container_cpu        = var.container_cpu
  container_memory     = var.container_memory
  container_environment = var.container_environment
  container_health_check = var.container_health_check
  create_alb           = var.create_alb
  alb_health_check_path = var.alb_health_check_path
  create_worker        = var.create_worker
  worker_container_environment = var.worker_container_environment
  worker_container_command     = var.worker_container_command
  create_redis         = var.create_redis
  database_endpoint    = try(module.database[0].endpoint, "")
  database_port        = try(tostring(module.database[0].port), "")
  log_retention_days   = var.log_retention_days
  enable_container_insights = var.enable_container_insights
  ecs_min_healthy_percent   = var.ecs_min_healthy_percent
  ecs_max_percent           = var.ecs_max_percent
  enable_execute_command     = var.enable_execute_command
  tags                 = var.tags
}

module "delivery" {
  source = "./modules/delivery"
  count   = var.create_delivery ? 1 : 0

  providers = {
    aws.us-east-1 = aws.us-east-1
  }

  name_prefix              = var.name_prefix
  domain_name              = var.domain_name
  compute_endpoint         = try(module.compute[0].endpoint, "")
  create_route53_zone      = var.create_route53_zone
  zone_id                  = var.existing_zone_id
  acm_certificate_arn      = var.acm_certificate_arn
  create_frontend_bucket   = var.create_frontend_bucket
  frontend_bucket_name     = var.frontend_bucket_name
  s3_versioning_enabled    = var.s3_versioning_enabled
  s3_lifecycle_expiration_days = var.s3_lifecycle_expiration_days
  create_cloudfront_frontend = var.create_cloudfront_frontend
  create_cloudfront_api    = var.create_cloudfront_api
  cloudfront_function_path = var.cloudfront_function_path
  cloudfront_price_class   = var.cloudfront_price_class
  geo_restriction_type     = var.geo_restriction_type
  geo_restriction_locations = var.geo_restriction_locations
  create_ci_cd_user        = var.create_ci_cd_user
  tags                     = var.tags
}
