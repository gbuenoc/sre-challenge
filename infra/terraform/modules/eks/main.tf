module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "eks-${var.environment}"
  kubernetes_version = var.kubernetes_version

  addons = {} #create the cluster with no addons

  # Optional
  endpoint_public_access = var.endpoint_public_access

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  fargate_profiles = {
    coredns = {
      name = "coredns"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        }
      ]
      subnets = module.vpc.private_subnets
      tags = {
        Name = "eks-fargate-coredns"
      }
    }

    karpenter = {
      name = "karpenter"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            "app.kubernetes.io/name" = "karpenter"
          }
        }
      ]
      subnets = module.vpc.private_subnets
      tags = {
        Name = "eks-fargate-karpenter"
      }
    }
  }

  tags = {
    Environment              = var.environment
    Terraform                = "true"
    "karpenter.sh/discovery" = "eks-${var.environment}"
  }
}