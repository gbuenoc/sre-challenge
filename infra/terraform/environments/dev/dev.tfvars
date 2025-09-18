region          = "us-east-1"
environment     = "dev"
vpc_cidr        = "10.0.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
pods_cidr       = "100.64.0.0/16"

kubernetes_version     = "1.33"
endpoint_public_access = true

repositories = [
  "foxbit-backend",
  "foxbit-frontend"
]