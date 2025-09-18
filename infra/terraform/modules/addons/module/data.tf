
data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "default" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = local.cluster_name
}

data "aws_subnets" "subnets" {
  filter {
    name   = "tag:Name"
    values = ["*${var.subnets_filter_name}*"]
  }
}

data "aws_subnet" "subnet_1" {
  id = element(data.aws_subnets.subnets.ids, 0)
}
data "aws_subnet" "subnet_2" {
  id = element(data.aws_subnets.subnets.ids, 1)
}
data "aws_subnet" "subnet_3" {
  id = element(data.aws_subnets.subnets.ids, 2)
}

data "aws_security_group" "sg_node" {
  filter {
    name   = "tag:Name"
    values = ["*${var.sg_filter_name}*"]
  }
}

##AWS AMI Bottlerocket
data "aws_ssm_parameter" "bottlerocket_ami" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.cluster_version}/x86_64/latest/image_id"
}