# Kubernetes add-ons for your EKS cluster

## Tagging Subnets & Security Groups for Karpenter and AWS Load Balancer Controller

### 1. Karpenter (Node Autoscaling)

Karpenter discovers eligible subnets and security groups to launch new nodes based on tags. Without proper tagging, Karpenter won’t know where to provision resources.

- **Subnets** and **Security Groups**  must include the tag:
`karpenter.sh/discovery = <ClusterName>`

This ensures:
- Karpenter targets the correct network boundaries
- Resources are launched in the intended VPC and subnet zones
- Avoids ambiguity when multiple clusters share resources

### 2. AWS Load Balancer Controller (ALB/NLB)

The Load Balancer Controller uses tags to auto-discover which subnets and security groups to use when provisioning load balancers.

- **Subnets**:
- Public (internet-facing):  
  `kubernetes.io/role/elb = 1`
- Private (internal):  
  `kubernetes.io/role/internal-elb = 1`

- **Security Groups**:
- When multiple security groups are used, make sure only one is tagged with `kubernetes.io/cluster/<cluster-name>` to allow proper reconciliation of inbound/outbound rules.

Incorrect or missing subnet tags may lead to errors such as:
Failed to resolve 2 qualified subnets

