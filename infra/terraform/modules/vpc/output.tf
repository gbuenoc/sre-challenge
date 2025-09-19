output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Lista de subnets privadas"
  value       = module.vpc.private_subnets
}