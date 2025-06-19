variable "environment" {
  description = "The environment for which the ECR repository is being created"
  type        = string
  default     = "dev"
}

resource "aws_ecr_repository" "main" {
  name = "telehealth-liquibase"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ssm_parameter" "liquibase_ecr_repository_name" {
  name  = "/ecrs/${var.environment}/liquibase_repository_name"
  type  = "String"
  value = aws_ecr_repository.main.name
}