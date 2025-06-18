
data "aws_ssm_parameter" "vpc_id" {
    name = "/networking/${var.environment}/vpc_id"
}

data "aws_ssm_parameter" "public_subnets" {
    name = "/networking/${var.environment}/public_subnets"
}

data "aws_ssm_parameter" "certificate_arn" {
    name = "/certificates/${var.environment}/certificate_arn"
}

data "aws_ssm_parameter" "zone_id" {
    name = "/route53/zone_id"
}

data "aws_route53_zone" "main" {
    zone_id = data.aws_ssm_parameter.zone_id.value
}

locals {
    public_subnets = split(",", data.aws_ssm_parameter.public_subnets.value)
}
