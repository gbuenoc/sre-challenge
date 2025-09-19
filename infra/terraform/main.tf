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
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
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