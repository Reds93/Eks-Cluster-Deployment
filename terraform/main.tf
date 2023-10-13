module "base" {
  source = "./base"

  prefix = local.prefix
  region = local.region
  subnets = local.subnets
  security_groups = local.security_groups
}

module "eks_cluster" {
  source = "./eks_cluster"

  prefix = local.prefix
  region = local.region
  iam_role = local.iam_role
  eks_cluster_version = local.eks_cluster.version
  eks_cluster_addons = local.eks_cluster.addons

  subnet_ids = module.base.subnet_ids
  security_group_ids = module.base.security_group_ids
}


module "node_group" {
  source = "./node_group"

  dep = module.eks_cluster.dep_output

  prefix = local.prefix
  region = local.region
  iam_role = local.iam_role
  eks_cluster = local.eks_cluster
  eks_cluster_subnet_ids = module.base.subnet_ids
}

resource "null_resource" "deploy" {
  depends_on = [module.node_group]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region us-east-1 --name ${local.prefix}-cluster && kubectl apply -f ../namespace-webserver.yml && kubectl apply -f ../deployment.yml --namespace=webserver && kubectl apply -f ../service.yml --namespace=webserver"
  }
}

output "output-prefix" {
  value = local.prefix
}

output "output-region" {
  value = local.region
}

output "output-subnets" {
  value = join(",", [for subnet_id in module.base.subnet_ids : subnet_id])
}
