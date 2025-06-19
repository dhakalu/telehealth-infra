resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnets
  enable_deletion_protection = false

  security_groups = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.main.arn
    port              = 443
    protocol          = "HTTPS"
    ssl_policy        = "ELBSecurityPolicy-2016-08"
    certificate_arn   = data.aws_ssm_parameter.certificate_arn.value

    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "OK"
            status_code  = "200"
        }
    }
}

resource "aws_lb_listener_certificate" "https" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = data.aws_ssm_parameter.certificate_arn.value
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
        host        = "#{host}"
        path        = "/"
        port        = "443"
        protocol    = "HTTPS"
        query       = "#{query}"
        status_code = "HTTP_301"
    }
 }
}

resource "aws_route53_record" "alb_cname" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${var.environment}.${data.aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = 60
  records = ["dualstack.${aws_lb.main.dns_name}"]
}

resource "aws_ssm_parameter" "alb_listener_http_arn" {
    name  = "/http/${var.environment}/alb_listener_http_arn"
    type  = "String"
    value = aws_lb_listener.http.arn
}

resource "aws_ssm_parameter" "alb_listener_https_arn" {
    name  = "/http/${var.environment}/alb_listener_https_arn"
    type  = "String"
    value = aws_lb_listener.https.arn
}