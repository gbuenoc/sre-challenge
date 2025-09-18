module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs = var.azs

  private_subnets = var.private_subnets

  public_subnets = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  private_subnet_tags = {
    "karpenter.sh/discovery" = "eks-${var.environment}" # Required for Karpenter to discover usable subnets
    #"kubernetes.io/role/internal-elb" = 1 # Uncomment if Ingress Controller should use private subnets
  }

  public_subnet_tags = {
    #"kubernetes.io/role/elb" = 1 # Uncomment if Ingress Controller should use public subnets
  }

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }
}

# CIDR block and subnets for pods
resource "aws_vpc_ipv4_cidr_block_association" "cidr_pods" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = var.pods_cidr
}

resource "aws_subnet" "subnets_pods" {
  for_each = { for idx, az in var.azs : idx => az }

  vpc_id                  = module.vpc.vpc_id
  cidr_block              = cidrsubnet(var.pods_cidr, 8, each.key)
  availability_zone       = each.value
  map_public_ip_on_launch = false

  depends_on = [aws_vpc_ipv4_cidr_block_association.cidr_pods]

  tags = {
    Name        = "${var.environment}-subnet-pod-${each.key}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "pods_assoc" {
  for_each = aws_subnet.subnets_pods

  subnet_id      = each.value.id
  route_table_id = module.vpc.private_route_table_ids[tonumber(each.key)]
}