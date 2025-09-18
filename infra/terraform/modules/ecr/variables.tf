variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  description = "Nome do ambiente (dev, staging, prod)"
  type        = string
}

variable "repositories" {
  description = "Lista de nomes de repositórios ECR"
  type        = list(string)
}