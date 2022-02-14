variable "iam_path" {
  description = "If provided, all IAM roles will be created on this path."
  type        = string
  default     = "/"
}

variable "region" {
  default     = "us-east-2"
  type        = string
  description = "AWS region"
}
variable "environment"{
  description = "environment"
  type        = string
  default     = "dev"  
}

variable "permissions_boundary" {
  description = "If provided, all IAM roles will be created with this permissions boundary attached."
  type        = string
  default     = null
}

variable "eks" {
  description = "Override default values for target groups. See workers_group_defaults_defaults in local.tf for valid keys."
  type = object({
    cluster_name = string
    cluster_version = string
    tags = map(string)
    image_id = string
    key_name = string
    private_access_cidrs = list(string)
    public_access_cidrs = list(string)
    manage_aws_auth = bool
    node_group = list(object({
      disk_size = number,
      name = string, 
      scaling_config = map(string),
      instance_types  = list(string)
      tags = map(string)
    }))
  })
  default = {
    cluster_name = "demo-eks-1"
    cluster_version = "1.19"
    image_id = "ami-0ad418be69ef09deb"
    key_name = "eks-cluster"
    private_access_cidrs = ["10.0.0.0/16"]
    public_access_cidrs  =  ["0.0.0.0/0"]
    manage_aws_auth = true
    tags = {
        environment = "test"
    },
    node_group = [{
      name = "node_group_1", 
      scaling_config = {
        desired_size = 2,   
        max_size     = 2,
        min_size     = 1
      },
      disk_size = 50,
      instance_types  = ["t2.medium"],
      tags = {
        "environment" = "test"
      }
    }]     
  }
}

variable "vpc" {
  description = "vpc"
  type = object({
    cidr = string
    private_subnets = list(string)
    public_subnets = list(string)     
  })
  default = {
    cidr = "10.0.0.0/16"
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]    
  }
}