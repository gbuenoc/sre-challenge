module "vpc" {
  source          = "./modules/vpc"
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  azs             = var.azs
  pods_cidr       = var.pods_cidr
}

module "eks" {
  source             = "./modules/eks"
  environment        = var.environment
  kubernetes_version = var.kubernetes_version
  vpc_id             = data.aws_vpc.env_vpc.id
  private_subnet_ids = data.aws_subnets.private_subnet.ids
}

module "ecr" {
  source       = "./modules/ecr"
  environment  = var.environment
  repositories = var.repositories
}

module "addons" {
  source      = "./modules/addons"
  environment = var.environment
}