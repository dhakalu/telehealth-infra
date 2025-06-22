locals {
    name_prefix = "telehealth-${var.environment}"
    db_subnet_ids = split(",", data.aws_ssm_parameter.db_subnet_ids.value)
}

resource "aws_security_group" "db" {
    name        = "${local.name_prefix}-db-sg"
    description = "Security group for RDS DB instance"
    vpc_id      = data.aws_ssm_parameter.vpc_id.value

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    # temporary ingress rule to allow public access for testing purposes
    ingress {
        description      = "Allow access from the public subnets"
        from_port        = 5432
        to_port          = 5432
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.name_prefix}-db-sg"
    }
}

resource "aws_db_subnet_group" "postgres" {
    name       = "${local.name_prefix}-postgres-subnet-group"
    subnet_ids = local.db_subnet_ids
    tags = {
        Name = "${local.name_prefix}-postgres-subnet-group"
    }
}

resource "random_password" "password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "postgres" {
  identifier              = "${local.name_prefix}-postgres"
  engine                  = "postgres"
  engine_version          = "17.5"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.password.result
  db_subnet_group_name    = aws_db_subnet_group.postgres.name
  iam_database_authentication_enabled = true
  vpc_security_group_ids  = [aws_security_group.db.id]
  skip_final_snapshot     = true
  publicly_accessible     = true
  storage_encrypted       = true
  backup_retention_period = 7
  auto_minor_version_upgrade = true
  apply_immediately       = true
  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}

resource "aws_ssm_parameter" "db_security_group_id" {
    name  = "/rds/${var.environment}/db_security_group_id"
    type  = "String"
    value = aws_security_group.db.id
}

resource "aws_ssm_parameter" "db_endpoint" {
    name  = "/rds/${var.environment}/db_endpoint"
    type  = "String"
    value = aws_db_instance.postgres.address
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

resource "aws_ssm_parameter" "db_reader_endpoint" {
    name  = "/rds/${var.environment}/db_reader_endpoint"
    type  = "String"
    value = aws_db_instance.postgres.endpoint
}

output "postgres_endpoint" {
    value = aws_db_instance.postgres.endpoint
}
output "postgres_reader_endpoint" {
    value = aws_db_instance.postgres.endpoint
}

resource "aws_ssm_parameter" "aurora_password" {
    name      = "/rds/${var.environment}/aurora_password"
    type      = "SecureString"
    value     = random_password.password.result
    overwrite = true
}