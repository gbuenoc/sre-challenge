terraform {
  backend "s3" {
    bucket       = "tfstate-sre-challenge"
    key          = "${var.environment}/ecr/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}