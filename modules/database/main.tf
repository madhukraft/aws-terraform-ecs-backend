locals {
  engine_defaults = {
    postgres = { port = 5432 }
    mysql    = { port = 3306 }
    mariadb  = { port = 3306 }
  }
  default_port = lookup(local.engine_defaults, var.engine, { port = 5432 }).port
  db_port      = var.port != 5432 ? var.port : local.default_port
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-dbsubnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, { Name = "${var.name_prefix}-dbsubnets" })
}

resource "aws_security_group" "rds" {
  name   = "${var.name_prefix}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = local.db_port
    to_port         = local.db_port
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-rds-sg" })
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  storage_type          = var.storage_type
  db_name               = var.db_name
  username              = var.username
  password              = var.password
  port                  = local.db_port
  publicly_accessible   = var.publicly_accessible
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name  = aws_db_subnet_group.this.name

  skip_final_snapshot       = var.skip_final_snapshot
  deletion_protection       = var.deletion_protection
  backup_retention_period   = var.backup_retention_period
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name_prefix}-db-final-snapshot"

  tags = merge(var.tags, { Name = "${var.name_prefix}-db" })
}
