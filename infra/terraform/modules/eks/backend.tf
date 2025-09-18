terraform {
  backend "s3" {
    bucket       = "tfstate-sre-challenge"
    key          = "${var.environment}/eks/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}