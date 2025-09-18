resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)

  name                 = "${each.key}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}