output "ecr_backend_url" {
  value = aws_ecr_repository.repos["foxbit-backend"].repository_url
}

output "ecr_frontend_url" {
  value = aws_ecr_repository.repos["foxbit-frontend"].repository_url
}