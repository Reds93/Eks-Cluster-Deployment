variable "prefix" {}
variable "region" {}
variable "iam_role" {}
variable "eks_cluster_version" {}
variable "eks_cluster_addons" {}

variable "subnet_ids" {}
variable "security_group_ids" {}


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


data "aws_iam_role" "role" {
  name = var.iam_role
}

resource "aws_eks_cluster" "cluster" {
  name = "${var.prefix}-cluster"
  role_arn = data.aws_iam_role.role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  version = var.eks_cluster_version

  vpc_config {
    subnet_ids = [for k,v in var.subnet_ids : v]
    security_group_ids = [for k,v in var.security_group_ids : v]
  }

  tags = {
    Name = "${var.prefix}-cluster"
  }
}

resource "aws_eks_addon" "addon" {
  for_each = toset(var.eks_cluster_addons)

  cluster_name = "${var.prefix}-cluster"
  addon_name = each.value
  resolve_conflicts_on_update = "PRESERVE"

}

output "dep_output" {
  value = "ok"
}
