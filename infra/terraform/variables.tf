variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "pods_cidr" {
  type = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "addons" {
  description = "EKS addons to enable during cluster creation"
  type        = map(any)
  default     = {}
}

variable "endpoint_public_access" {
  description = "Whether the EKS cluster API endpoint should be publicly accessible"
  type        = bool
  default     = false
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grants admin permissions to the IAM identity that creates the cluster"
  type        = bool
  default     = true
}

variable "repositories" {
  description = "Lista de nomes de repositórios ECR"
  type        = list(string)
}