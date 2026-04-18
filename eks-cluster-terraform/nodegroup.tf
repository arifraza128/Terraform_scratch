module "eks_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.0"

  cluster_name    = module.eks.cluster_name
  cluster_version = module.eks.cluster_version

  name            = "node-group"
  subnet_ids      = module.vpc.private_subnets

  instance_types = [var.node_instance_type]

  desired_size = 2
  max_size     = 3
  min_size     = 1
}
