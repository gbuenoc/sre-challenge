locals {
  region           = var.region
  cluster_name     = var.cluster_name
  cluster_endpoint = data.aws_eks_cluster.default.endpoint
  oidc             = substr(data.aws_eks_cluster.default.identity[0].oidc[0].issuer, 8, length(data.aws_eks_cluster.default.identity[0].oidc[0].issuer))
  account_id       = data.aws_caller_identity.current.account_id
  vpc_id           = data.aws_eks_cluster.default.vpc_config[0].vpc_id
  sg_node          = data.aws_security_group.sg_node.id
  subnet_1         = data.aws_subnet.subnet_1.id
  subnet_2         = data.aws_subnet.subnet_2.id
  subnet_3         = data.aws_subnet.subnet_3.id
  az_1             = data.aws_subnet.subnet_1.availability_zone
  az_2             = data.aws_subnet.subnet_2.availability_zone
  az_3             = data.aws_subnet.subnet_3.availability_zone

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