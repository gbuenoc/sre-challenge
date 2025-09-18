terraform {
  backend "s3" {
    bucket       = "tfstate-sre-challenge"
    key          = "${var.environment}/addons/terraform.tfstate"
    region       = var.region
    use_lockfile = true
  }
}