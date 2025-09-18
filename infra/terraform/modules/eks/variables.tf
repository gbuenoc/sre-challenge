variable "region" {
  type    = string
  default = "us-east-1"
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

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS control plane and workloads"
  type        = list(string)
}