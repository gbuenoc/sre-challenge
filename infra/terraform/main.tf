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
  region      = var.region
  vpc_id = module.vpc.vpc_id
  azs = var.azs
  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_oidc     = module.eks.cluster_oidc_issuer_url
  private_subnet_ids = module.vpc.private_subnet_ids
  node_security_group_id = module.eks.node_security_group_id
}