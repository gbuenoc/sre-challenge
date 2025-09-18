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

  vpc_id                   = data.aws_vpc.env_vpc.id
  subnet_ids               = data.aws_subnets.private_subnet.ids
  control_plane_subnet_ids = data.aws_subnets.private_subnet.ids

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
      subnets = data.aws_subnets.lab_private.ids
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
      subnets = data.aws_subnets.lab_private.ids
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