variable "prefix" {}
variable "region" {}
variable "subnets" {}
variable "security_groups" {}

terraform {
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = "~> 5.0"
		}
	}
}

provider "aws" {
	region = var.region
}


resource "aws_vpc" "vpc" {
	cidr_block = "10.1.0.0/16"

	tags = {
		Name = "${var.prefix}-vpc""
	}
}

resource "aws_subnet" "subnet" {
  for_each = var.subnets

	vpc_id = aws_vpc.vpc.id
	cidr_block = each.value.cidr_block
  availability_zone = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

	tags = {
		Name = "${var.prefix}-subnet-${each.key}"
	}
}

resource "aws_network_interface" "nic" {
  for_each = var.subnets

	subnet_id = aws_subnet.subnet["${each.key}"].id

  tags = {
    Name = "${var.prefix}-nic-${each.key}"
  }
}

resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "rtb" {
	vpc_id = aws_vpc.vpc.id

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.igw.id
	}

  tags = {
    Name = "${var.prefix}-rtb"
  }
}

resource "aws_route_table_association" "rtba" {
  for_each = var.subnets

	subnet_id = aws_subnet.subnet["${each.key}"].id
	route_table_id = aws_route_table.rtb.id
}

resource "aws_security_group" "sg" {
  for_each = var.security_groups

	vpc_id = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = each.value.ingress

    content {
      from_port = ingress.value.from_port
      to_port	= ingress.value.to_port
      protocol = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = each.value.egress

    content {
      from_port = egress.value.from_port
      to_port	= egress.value.to_port
      protocol = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "${var.prefix}-sg-${each.key}"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = {for k,v in aws_subnet.subnet : k => v.id}
}

output "security_group_ids" {
  value = {for k,v in aws_security_group.sg : k => v.id}
}
