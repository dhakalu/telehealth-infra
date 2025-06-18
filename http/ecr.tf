resource "aws_ecr_repository" "main" {
  name = "${local.name_prefix}-ecr-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ssm_parameter" "ecr_repository_name" {
  name  = "/http/${var.environment}/ecr_repository_name"
  type  = "String"
  value = aws_ecr_repository.main.name
}