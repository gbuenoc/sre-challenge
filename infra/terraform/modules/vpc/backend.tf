terraform {
  backend "s3" {
    bucket       = "tfstate-sre-challenge"
    key          = "${var.environment}/vpc/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}