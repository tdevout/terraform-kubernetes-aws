provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name                 = "${var.environment}-eks-vpc"
  cidr                 =  var.vpc.cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.vpc.private_subnets
  public_subnets       = var.vpc.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.eks.cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
