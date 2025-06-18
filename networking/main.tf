locals {
  app = "telehealth"
  domain = "common"
  name_prefix="${local.app}-${local.domain}-${var.environment}"
  zones = ["a", "b", "c", "d"]
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_subnet" "public" {    
    count = length(local.zones)
    vpc_id   = aws_vpc.main.id
    cidr_block = cidrsubnet(var.public_subnet_cidr, 2, count.index)
    map_public_ip_on_launch = true
    availability_zone = "${var.aws_region}${local.zones[count.index]}"
    tags = {
        Name = "${local.name_prefix}-public-subnet-${local.zones[count.index]}"
    }

}

resource "aws_subnet" "private" {
    count = length(local.zones)
    vpc_id   = aws_vpc.main.id
    cidr_block = cidrsubnet(var.private_subnet_cidr, 2, count.index)
    availability_zone = "${var.aws_region}${local.zones[count.index]}"
    tags = {
        Name = "${local.name_prefix}-private-subnet-${local.zones[count.index]}"
    }
}

resource "aws_subnet" "db" {
    count = length(local.zones)
    vpc_id   = aws_vpc.main.id
    cidr_block = cidrsubnet(var.db_subnet_cidr, 2, count.index)
    availability_zone = "${var.aws_region}${local.zones[count.index]}"
    tags = {
        Name = "${local.name_prefix}-db-subnet-${local.zones[count.index]}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${local.name_prefix}-public-rt"
    }
}

resource "aws_route" "public_internet_access" {
    route_table_id         = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
    count = length(local.zones)
    subnet_id      = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${local.name_prefix}-private-rt"
    }
}

resource "aws_route_table_association" "private" {
    count = length(local.zones)
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "db" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${local.name_prefix}-db-rt"
    }
}

resource "aws_route_table_association" "db" {
    count = length(local.zones)
    subnet_id      = aws_subnet.db[count.index].id
    route_table_id = aws_route_table.db.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_ssm_parameter" "vpc_id" {
    name  = "/networking/${var.environment}/vpc_id"
    type  = "String"
    value = aws_vpc.main.id
}

resource "aws_ssm_parameter" "public_subnets" {
    name  = "/networking/${var.environment}/public_subnets"
    type  = "String"
    value = join(",", aws_subnet.public[*].id)
}

resource "aws_ssm_parameter" "private_subnets" {
    name  = "/networking/${var.environment}/private_subnets"
    type  = "String"
    value = join(",", aws_subnet.private[*].id)
}

resource "aws_ssm_parameter" "db_subnets" {
    name  = "/networking/${var.environment}/db_subnets"
    type  = "String"
    value = join(",", aws_subnet.db[*].id)
}