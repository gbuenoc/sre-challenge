region          = "us-east-1"
environment     = "prod"
vpc_cidr        = "10.1.0.0/16"
azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
pods_cidr       = "100.65.0.0/16"

kubernetes_version     = "1.33"
endpoint_public_access = true

repositories = [
  "foxbit-backend",
  "foxbit-frontend"
]