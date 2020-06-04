
##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
   tags = {
    Name = "usw2-dev1"
  }
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_subnet" "all" {
  for_each = data.aws_subnet_ids.all.ids
  id       = each.value
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

#####
# DB
#####
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.identifier

  engine            = "postgres"
  engine_version    = "9.6.9"
  instance_class    = var.instanceclass
  allocated_storage = 5
  storage_encrypted = false

  #name     = var.rdsname
  username = var.username
  password = var.password
  port     = "5432"

  vpc_security_group_ids = ["${data.aws_security_group.default.id}"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  #multi_az = true

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Name = var.identifier
    Role = var.role
    XMCC = var.xmcc
    APPNAME = var.appname
    DeploymentState = var.dpstate
  }

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.all.ids

  # DB parameter group
  family = "postgres9.6"

  # DB option group
  major_engine_version = "9.6"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "demodb"

  # Database Deletion Protection
  deletion_protection = false
}