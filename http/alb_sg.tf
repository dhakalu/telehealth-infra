resource "aws_security_group" "alb_sg" {
    name        = "alb-sg"
    description = "Allow HTTP and HTTPS traffic from the internet"
    vpc_id      = data.aws_ssm_parameter.vpc_id.value

    ingress {
        description = "Allow HTTP from anywhere"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "Allow HTTPS from anywhere"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "Allow all outbound traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${local.name_prefix}-alb-sg"
    }
}

resource "aws_ssm_parameter" "alb_subnet_id" {
    name  = "/http/alb/subnet_id"
    type  = "String"
    value = aws_security_group.alb_sg.id
}