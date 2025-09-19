locals {
  region           = var.region
  cluster_name     = var.cluster_name
  cluster_endpoint = var.cluster_endpoint
  oidc             = var.cluster_oidc
  account_id       = data.aws_caller_identity.current.account_id
  vpc_id           = var.vpc_id
  subnet_1         = var.private_subnet_ids[0]
  subnet_2         = var.private_subnet_ids[1]
  subnet_3         = var.private_subnet_ids[2]
  az_1             = var.azs[0]
  az_2             = var.azs[1]
  az_3             = var.azs[2]
  sg_node          = var.node_security_group_id

  karpenter_values = var.karpenter_enable ? templatefile("${path.module}/helm-values/values-karpenter.tpl.yaml", {
    account_id           = local.account_id
    controller_role_name = aws_iam_role.eks_karpenter_role_controller[0].name
    cluster_name         = local.cluster_name
    cluster_endpoint     = local.cluster_endpoint
  }) : null

  autoscaler_values = templatefile("${path.module}/helm-values/values-autoscaler.tpl.yaml", {
    region       = local.region
    cluster_name = local.cluster_name
  })

  alb_controller_values = templatefile("${path.module}/helm-values/values-alb-controller.tpl.yaml", {
    cluster_name = local.cluster_name
    region       = local.region
    vpc_id       = local.vpc_id
  })
}