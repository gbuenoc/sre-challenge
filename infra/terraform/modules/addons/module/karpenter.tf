############################################## Helm ##############################################
resource "helm_release" "karpenter" {
  count      = var.karpenter_enable ? 1 : 0
  name       = "karpenter"
  chart      = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  version    = var.karpenter_version
  namespace  = "kube-system"

  values = [local.karpenter_values]

  depends_on = [
    aws_eks_addon.coredns,
    aws_eks_addon.kube_proxy,
    helm_release.vpc_cni,
  ]
}

############################################## AWS Role for Karpenter Node ##############################################
resource "aws_iam_role" "eks_karpenter_role_node" {
  count = var.karpenter_enable ? 1 : 0
  name  = "AmazonEKSKarpenterRoleNode_terraform"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

############################################## Attaching required AWS Policies for Karpenter Node Role ##############################################
resource "aws_iam_role_policy_attachment" "karpenter_node_worker_node_policy" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role_node[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni_policy" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role_node[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr_pull" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role_node[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role_node[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

############################################## Add Karpenter Node Role to access entry ########################################
resource "aws_eks_access_entry" "karpenter_nodes" {
  count         = var.karpenter_enable ? 1 : 0
  cluster_name  = local.cluster_name
  principal_arn = aws_iam_role.eks_karpenter_role_node[count.index].arn
  type          = "EC2_LINUX"

  depends_on = [
    aws_iam_role.eks_karpenter_role_node,
    aws_iam_role_policy_attachment.karpenter_node_worker_node_policy,
    aws_iam_role_policy_attachment.karpenter_node_cni_policy,
    aws_iam_role_policy_attachment.karpenter_node_ecr_pull,
    aws_iam_role_policy_attachment.karpenter_node_ssm,
    helm_release.karpenter
  ]
}

############################################## AWS Role for Karpenter Controller ##############################################
resource "aws_iam_role" "eks_karpenter_role_controller" {
  count = var.karpenter_enable ? 1 : 0
  name  = "AmazonEKSKarpenterRoleController_terraform"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Federated" : "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc}"
          },
          "Action" : "sts:AssumeRoleWithWebIdentity",
          "Condition" : {
            "StringEquals" : {
              "${local.oidc}:aud" : "sts.amazonaws.com",
              "${local.oidc}:sub" : "system:serviceaccount:kube-system:karpenter-sa"
            }
          }
        }
      ]
  })
}

############################################## Creating custom policy for Karpenter Controller Role ##############################################
resource "aws_iam_policy" "eks_karpenter_policy" {
  count       = var.karpenter_enable ? 1 : 0
  name        = "KarpenterControllerPolicy_terraform"
  description = "Policy to karpenter"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Karpenter",
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "ConditionalEC2Termination",
        "Effect" : "Allow",
        "Action" : "ec2:TerminateInstances",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid" : "PassNodeIAMRole",
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "arn:aws:iam::${local.account_id}:role/AmazonEKSKarpenterRoleNode_terraform"
      },
      {
        "Sid" : "EKSClusterEndpointLookup",
        "Effect" : "Allow",
        "Action" : "eks:DescribeCluster",
        "Resource" : "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.cluster_name}"
      },
      {
        "Sid" : "AllowScopedInstanceProfileCreationActions",
        "Effect" : "Allow",
        "Action" : ["iam:CreateInstanceProfile"],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : "${local.region}"
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileTagActions",
        "Effect" : "Allow",
        "Action" : ["iam:TagInstanceProfile"],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "${local.region}",
            "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : "${local.region}"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileActions",
        "Effect" : "Allow",
        "Action" : [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "${local.region}"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowInstanceProfileReadActions",
        "Effect" : "Allow",
        "Action" : "iam:GetInstanceProfile",
        "Resource" : "*"
      },
      {
        "Sid" : "AllowInterruptionQueueAccess",
        "Effect" : "Allow",
        "Action" : [
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource" : "arn:aws:sqs:${local.region}:${local.account_id}:${local.cluster_name}"
      }
    ]
  })
}

############################################## Attaching custom AWS Policy for Karpenter Controller Role #########################################
resource "aws_iam_role_policy_attachment" "attach_karpenter_controller_role_policy" {
  count      = var.karpenter_enable ? 1 : 0
  role       = aws_iam_role.eks_karpenter_role_controller[count.index].name
  policy_arn = aws_iam_policy.eks_karpenter_policy[count.index].arn
}

############################################## Karpenter Interruption Queue for Spot Instance #########################################
resource "aws_sqs_queue" "karpenter_interruption_queue" {
  count = var.karpenter_enable ? 1 : 0
  name  = local.cluster_name
  depends_on = [
    helm_release.karpenter
  ]
}

############################################## EC2NodeClass ##############################################

resource "kubectl_manifest" "karpenter_node_class" {
  count     = var.karpenter_enable ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: bottlerocket
    spec:
      amiFamily: Bottlerocket
      amiSelectorTerms:
        - id: ${data.aws_ssm_parameter.bottlerocket_ami.value}
      blockDeviceMappings:
        - deviceName: /dev/xvdb
          ebs:
            volumeSize: ${var.disk_size}Gi
            volumeType: gp3
            encrypted: true
            iops: ${var.disk_iops}
            deleteOnTermination: true
      role: ${aws_iam_role.eks_karpenter_role_node[0].name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${local.cluster_name}
      tags:
        karpenter.sh/discovery: ${local.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

############################################## Node Pools ##############################################

resource "kubectl_manifest" "karpenter_node_pool_tools" {
  count     = var.karpenter_enable ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: tools
    spec:
      template:
        metadata:
          labels:
            workload: tools
        spec:
          nodeClassRef:
            name: bottlerocket
            kind: EC2NodeClass
            group: karpenter.k8s.aws
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t", "c", "m"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["1", "2", "4", "8"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ${jsonencode(var.capacity_type_pool_tools)}
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_pool_apps" {
  count     = var.karpenter_enable ? 1 : 0
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: apps
    spec:
      template:
        metadata:
          labels:
            workload: apps
        spec:
          nodeClassRef:
            name: bottlerocket
            kind: EC2NodeClass
            group: karpenter.k8s.aws
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["t", "c", "m"]
            - key: "karpenter.k8s.aws/instance-cpu"
              operator: In
              values: ["4", "8"]
            - key: "karpenter.k8s.aws/instance-hypervisor"
              operator: In
              values: ["nitro"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ${jsonencode(var.capacity_type_pool_apps)}
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}