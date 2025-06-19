data "aws_ssm_parameter" "db_subnet_ids" {
    name = "/networking/${var.environment}/db_subnets"
}

data "aws_ssm_parameter" "vpc_id" {
    name = "/networking/${var.environment}/vpc_id"
}