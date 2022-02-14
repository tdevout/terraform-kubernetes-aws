region = "us-east-2"
environment = "dev"

### vpc cluster 
vpc = {
    cidr = "10.0.0.0/16"
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]    
}

### EKS cluster 
eks = {
    cluster_name = "cluster-dev"
    cluster_version = "1.19"
    image_id = "ami-0ad418be69ef09deb"
    key_name = "eks-cluster"
    private_access_cidrs = ["10.0.0.0/16"]
    public_access_cidrs  =  ["0.0.0.0/0"] 
    manage_aws_auth = true   
    tags = {
        environment = "dev"
    },
    node_group = [
        {
            name = "cluster-dev-node-group-1", 
            scaling_config = {
                desired_size = 2,   
                max_size     = 10,
                min_size     = 1
            },
            disk_size = 100,
            instance_types  = ["t2.medium"],
            tags = {
                "environment" = "cluster-dev-node-group-1"
            }
        }         
    ]        
}

