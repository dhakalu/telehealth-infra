variable "domain_name" {
  description = "The domain name for the certificate."
  type        = string
  default = "amruta.online"
}

variable "environment" {
  description = "Name the environment"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "The AWS region where the certificate will be created."
  type        = string
  default     = "us-east-1"
}
locals {
    full_domain_name = "${var.environment}.${var.domain_name}"
}

data "aws_ssm_parameter" "zone_id" {
    name = "/route53/zone_id"
}

data "aws_route53_zone" "main" {
    zone_id = data.aws_ssm_parameter.zone_id.value
}


resource "aws_acm_certificate" "public_cert" {
  domain_name       = local.full_domain_name
  validation_method = "DNS"
  region = var.region

  validation_option {
    domain_name = local.full_domain_name
    validation_domain = var.domain_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
for_each = {
    for dvo in aws_acm_certificate.public_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id  
}

output "certificate_arn" {
  value = aws_acm_certificate.public_cert.arn
}

resource "aws_ssm_parameter" "certificate_arn" {
    name  = "/certificates/${var.environment}/certificate_arn"
    type  = "String"
    value = aws_acm_certificate.public_cert.arn
}
