variable "prefix" {}
variable "region" {}
variable "subnet_ids" {}

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

data "aws_vpc" "vpc" {
  filter {
    name = "tag:Name"
    values = ["${var.prefix}-vpc"]
  }
}

data "aws_security_group" "sg" {
  filter {
    name = "tag:Name"
    values = ["${var.prefix}-sg-cluster"]
  }

}

data "aws_eks_node_group" "nodegroup" {
  cluster_name = "${var.prefix}-cluster"
  node_group_name = "${var.prefix}-nodegroup"
}

resource "aws_lb_target_group" "targetgroup" {
  name     = "${var.prefix}-targetgroup"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.vpc.id

  tags = {
    Name = "${var.prefix}-targetgroup"
  }
}

resource "aws_lb" "lb" {
  name = "${var.prefix}-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [data.aws_security_group.sg.id]
  subnets = split(",", var.subnet_ids)

  tags = {
    Name = "${var.prefix}-lb"
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.targetgroup.arn
  }
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  for_each = { for asg in data.aws_eks_node_group.nodegroup.resources[0].autoscaling_groups : asg.name => asg.name }

  autoscaling_group_name = each.value
  lb_target_group_arn = aws_lb_target_group.targetgroup.arn
}

output "output-lburl" {
  value = aws_lb.lb.dns_name
}
