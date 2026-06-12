data "aws_region" "current" {}

locals {
  is_ec2    = var.launch_type == "EC2"
  is_fargate = var.launch_type == "FARGATE"

  network_mode = local.is_fargate ? "awsvpc" : "bridge"

  app_environment = merge(
    {
      AWS_REGION    = data.aws_region.current.name
      DB_HOST       = var.database_endpoint
      DB_PORT       = var.database_port
      REDIS_URL     = local.is_ec2 ? "redis://localhost:6379/0" : ""
      REDIS_HOST    = local.is_ec2 ? "localhost" : ""
      REDIS_PORT    = "6379"
    },
    var.container_environment
  )

  worker_environment = merge(
    local.app_environment,
    var.worker_container_environment
  )
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-cluster" })
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = "${var.name_prefix}-log-app" })
}

resource "aws_cloudwatch_log_group" "redis" {
  count             = var.create_redis ? 1 : 0
  name              = "/ecs/${var.name_prefix}-redis"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, { Name = "${var.name_prefix}-log-redis" })
}

resource "aws_iam_role" "ecs_instance" {
  count = local.is_ec2 ? 1 : 0
  name  = "${var.name_prefix}-ecs-instance-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-ecs-instance-role" })
}

resource "aws_iam_role_policy_attachment" "ecs_instance" {
  count      = local.is_ec2 ? 1 : 0
  role       = aws_iam_role.ecs_instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  count = local.is_ec2 ? 1 : 0
  name  = "${var.name_prefix}-ecs-instance-profile"
  role  = aws_iam_role.ecs_instance[0].name

  tags = merge(var.tags, { Name = "${var.name_prefix}-ecs-instance-profile" })
}

resource "aws_iam_role" "task_exec" {
  name = "${var.name_prefix}-task-exec-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-task-exec-role" })
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role       = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task_role" {
  name = "${var.name_prefix}-task-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })

  tags = merge(var.tags, { Name = "${var.name_prefix}-task-role" })
}

resource "aws_iam_role_policy_attachment" "task_role_ssm" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-app"
  network_mode             = local.network_mode
  requires_compatibilities = [var.launch_type]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${var.container_image}:${var.container_tag}"
    essential = true
    portMappings = var.app_port > 0 ? [{
      containerPort = var.app_port
      hostPort      = local.is_fargate ? var.app_port : (var.create_alb ? 0 : var.app_port)
      protocol      = "tcp"
    }] : []
    environment = [for k, v in local.app_environment : { name = k, value = v }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "app"
      }
    }
    healthCheck = {
      command     = var.container_health_check.command
      interval    = var.container_health_check.interval
      timeout     = var.container_health_check.timeout
      retries     = var.container_health_check.retries
      startPeriod = var.container_health_check.start_period
    }
  }])
}

resource "aws_ecs_task_definition" "worker" {
  count                    = var.create_worker ? 1 : 0
  family                   = "${var.name_prefix}-worker"
  network_mode             = local.network_mode
  requires_compatibilities = [var.launch_type]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode(concat([
    {
      name      = "worker"
      image     = "${var.container_image}:${var.container_tag}"
      essential = true
      command   = var.worker_container_command
      environment = [for k, v in local.worker_environment : { name = k, value = v }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "worker"
        }
      }
    }
  ], var.create_worker && var.worker_container_command != null ? [] : []))
}

resource "aws_ecs_task_definition" "redis" {
  count                    = var.create_redis ? 1 : 0
  family                   = "${var.name_prefix}-redis"
  network_mode             = local.network_mode
  requires_compatibilities = [var.launch_type]
  cpu                      = 256
  memory                   = 256
  execution_role_arn       = aws_iam_role.task_exec.arn
  task_role_arn            = aws_iam_role.task_role.arn

  container_definitions = jsonencode([{
    name      = "redis"
    image     = "redis:alpine"
    essential = true
    portMappings = [{
      containerPort = 6379
      hostPort      = local.is_fargate ? 6379 : 6379
      protocol      = "tcp"
    }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.redis[0].name
        awslogs-region        = data.aws_region.current.name
        awslogs-stream-prefix = "redis"
      }
    }
    healthCheck = {
      command     = ["CMD-SHELL", "redis-cli ping || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])
}

resource "aws_launch_template" "ecs" {
  count = local.is_ec2 ? 1 : 0

  name_prefix   = "${var.name_prefix}-ecs-"
  image_id      = var.ecs_ami_id
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance[0].name
  }

  vpc_security_group_ids = [var.ecs_security_group_id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo "ECS_CLUSTER=${aws_ecs_cluster.this.name}" >> /etc/ecs/ecs.config
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-ecs-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  count = local.is_ec2 ? 1 : 0

  name_prefix       = "${var.name_prefix}-ecs-asg-"
  vpc_zone_identifier = var.public_subnet_ids
  min_size          = var.ecs_asg_min_size
  max_size          = var.ecs_asg_max_size
  desired_capacity  = var.ecs_asg_desired_capacity
  protect_from_scale_in = true

  launch_template {
    id      = aws_launch_template.ecs[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value              = "${var.name_prefix}-ecs-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value              = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "ecs" {
  count = local.is_ec2 && !var.create_alb ? 1 : 0
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-eip" })
}

locals {
  app_endpoint = local.is_ec2 && !var.create_alb ? try(aws_eip.ecs[0].public_ip, "") : try(aws_lb.this[0].dns_name, "")
}

resource "aws_security_group" "alb" {
  count  = var.create_alb ? 1 : 0
  name   = "${var.name_prefix}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb-sg" })
}

resource "aws_lb" "this" {
  count                      = var.create_alb ? 1 : 0
  name                       = "${var.name_prefix}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb[0].id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false

  tags = merge(var.tags, { Name = "${var.name_prefix}-alb" })
}

resource "aws_lb_target_group" "this" {
  count    = var.create_alb ? 1 : 0
  name     = "${var.name_prefix}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.alb_health_check_path
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-tg" })
}

resource "aws_lb_listener" "http" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }
}

resource "aws_ecs_service" "app" {
  name                   = "${var.name_prefix}-app"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.app.arn
  desired_count          = 1
  enable_execute_command = var.enable_execute_command
  launch_type            = var.launch_type

  deployment_minimum_healthy_percent = var.ecs_min_healthy_percent
  deployment_maximum_percent         = var.ecs_max_percent

  dynamic "network_configuration" {
    for_each = local.is_fargate ? [1] : []
    content {
      subnets          = var.public_subnet_ids
      security_groups  = [var.ecs_security_group_id]
      assign_public_ip = true
    }
  }

  dynamic "load_balancer" {
    for_each = var.create_alb ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.this[0].arn
      container_name   = "app"
      container_port   = var.app_port
    }
  }

  depends_on = [aws_autoscaling_group.ecs]
}

resource "aws_ecs_service" "app_redis" {
  count                  = var.create_redis ? 1 : 0
  name                   = "${var.name_prefix}-redis"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.redis[0].arn
  desired_count          = 1
  enable_execute_command = var.enable_execute_command
  launch_type            = var.launch_type

  deployment_minimum_healthy_percent = var.ecs_min_healthy_percent
  deployment_maximum_percent         = var.ecs_max_percent

  dynamic "network_configuration" {
    for_each = local.is_fargate ? [1] : []
    content {
      subnets          = var.public_subnet_ids
      security_groups  = [var.ecs_security_group_id]
      assign_public_ip = true
    }
  }
}

resource "aws_ecs_service" "worker" {
  count                  = var.create_worker ? 1 : 0
  name                   = "${var.name_prefix}-worker"
  cluster                = aws_ecs_cluster.this.id
  task_definition        = aws_ecs_task_definition.worker[0].arn
  desired_count          = 1
  enable_execute_command = var.enable_execute_command
  launch_type            = var.launch_type

  deployment_minimum_healthy_percent = var.ecs_min_healthy_percent
  deployment_maximum_percent         = var.ecs_max_percent

  dynamic "network_configuration" {
    for_each = local.is_fargate ? [1] : []
    content {
      subnets          = var.public_subnet_ids
      security_groups  = [var.ecs_security_group_id]
      assign_public_ip = true
    }
  }
}
