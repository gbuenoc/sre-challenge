data "aws_vpcs" "env" {
  filter {
    name   = "tag:Name"
    values = ["${var.environment}-vpc"]
  }
  depends_on = [module.vpc]
}

data "aws_vpc" "env_vpc" {
  id         = data.aws_vpcs.env.ids[0]
  depends_on = [module.vpc]
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.env_vpc.id]

  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
  depends_on = [module.vpc]
}