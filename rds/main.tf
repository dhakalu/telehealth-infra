locals {
    name_prefix = "telehealth-${var.environment}"
    db_subnet_ids = split(",", data.aws_ssm_parameter.db_subnet_ids.value)
}

resource "aws_security_group" "db" {
    name        = "${local.name_prefix}-db-sg"
    description = "Security group for Aurora DB cluster"
    vpc_id      = data.aws_ssm_parameter.vpc_id.value

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.name_prefix}-db-sg"
    }
}

resource "aws_db_subnet_group" "aurora" {
    name       = "${local.name_prefix}-aurora-subnet-group"
    subnet_ids = local.db_subnet_ids
    tags = {
        Name = "${local.name_prefix}-aurora-subnet-group"
    }
}

resource "random_password" "password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${local.name_prefix}-aurora-cluster"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "15.4"
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = random_password.password.result
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true
  iam_database_authentication_enabled = true
  enable_http_endpoint = true

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }
}

resource "aws_rds_cluster_instance" "aurora_instance" {
  count              = var.instance_count
  identifier         = "telehealth-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version
}

resource "aws_ssm_parameter" "db_security_group_id" {
    name  = "/rds/${var.environment}/db_security_group_id"
    type  = "String"
    value = aws_security_group.db.id
}

resource "aws_ssm_parameter" "aurora_endpoint" {
    name  = "/rds/${var.environment}/aurora_endpoint"
    type  = "String"
    value = aws_rds_cluster.aurora.endpoint
}

resource "aws_ssm_parameter" "db_name" {
    name  = "/rds/${var.environment}/db_name"
    type  = "String"
    value =  var.db_name
}

resource "aws_ssm_parameter" "db_username" {
    name  = "/rds/${var.environment}/db_username"
    type  = "String"
    value =  var.db_username
}

resource "aws_ssm_parameter" "aurora_reader_endpoint" {
    name  = "/rds/${var.environment}/aurora_reader_endpoint"
    type  = "String"
    value = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_endpoint" {
    value = aws_rds_cluster.aurora.endpoint
}
output "aurora_reader_endpoint" {
    value = aws_rds_cluster.aurora.reader_endpoint
}

resource "aws_ssm_parameter" "aurora_password" {
    name      = "/rds/${var.environment}/aurora_password"
    type      = "SecureString"
    value     = random_password.password.result
    overwrite = true
}