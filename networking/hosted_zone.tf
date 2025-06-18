resource "aws_route53_zone" "main" {
  name = "amruta.online"
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

resource "aws_ssm_parameter" "zone_id" {
    name  = "/route53/zone_id"
    type  = "String"
    value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}
