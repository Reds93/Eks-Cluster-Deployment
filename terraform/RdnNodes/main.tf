variable "dep" {}
variable "prefix" {}
variable "region" {}
variable "iam_role" {}
variable "eks_cluster" {}
variable "eks_cluster_subnet_ids" {}


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


resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = data.aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = data.aws_iam_role.role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = data.aws_iam_role.role.name
}



resource "aws_eks_node_group" "nodegroup" {
  cluster_name    = "${var.prefix}-cluster"
  node_group_name = "${var.prefix}-nodegroup"
  node_role_arn   = data.aws_iam_role.role.arn
  subnet_ids      = [for k,v in var.eks_cluster_subnet_ids : v]
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = var.eks_cluster.scaling_config.desired_size
    max_size     = var.eks_cluster.scaling_config.max_size
    min_size     = var.eks_cluster.scaling_config.min_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "${var.prefix}-nodegroup"
  }
}
