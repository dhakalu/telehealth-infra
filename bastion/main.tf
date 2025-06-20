variable "environment" {
  description = "The environment for which the bastion host is being created."
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/networking/${var.environment}/vpc_id"
  
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/networking/${var.environment}/public_subnets"
}

data "aws_ssm_parameter" "db_sg" {
  name = "/rds/${var.environment}/db_security_group_id"
}

resource "aws_vpc_security_group_ingress_rule" "db_access" {
  security_group_id = data.aws_ssm_parameter.db_sg.value
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  referenced_security_group_id = aws_security_group.this.id
}

data "aws_ec2_managed_prefix_list" "ec2_instance_connect" {
    name = "com.amazonaws.us-east-1.ec2-instance-connect"
}

resource "aws_security_group" "this" {
  name        = "bastion-sg"
  description = "Security group for the bastion host"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

    ingress {
        description      = "Allow HTTPS for AWS Session Manager"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        description      = "Allow SSH from EC2 Instance Connect"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        prefix_list_ids  = [data.aws_ec2_managed_prefix_list.ec2_instance_connect.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}




resource "aws_iam_instance_profile" "ssm" {
  name = "ec2-ssm-instance-profile"
  role = data.aws_iam_role.ssm.name
}

data "aws_iam_role" "ssm" {
  name = "bastion-ec2-role"
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = element(split(",", data.aws_ssm_parameter.public_subnet_ids.value), 0)
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm.name
  associate_public_ip_address = true
  tags = {
    Name = "telehealth-bastion"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
