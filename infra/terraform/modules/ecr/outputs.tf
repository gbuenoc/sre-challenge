output "ecr_backend_url" {
  value = aws_ecr_repository.repos["app-backend"].repository_url
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.repos["app-frontend"].repository_url
}