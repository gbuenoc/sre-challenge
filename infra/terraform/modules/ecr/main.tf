resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)

  name                 = "${each.value}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}