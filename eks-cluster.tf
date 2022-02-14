resource "aws_iam_role" "workers" {
  name                  = "workers_iam_role"
  assume_role_policy    = data.aws_iam_policy_document.workers_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy", "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly","arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy","arn:aws:iam::aws:policy/AmazonRoute53DomainsFullAccess","arn:aws:iam::aws:policy/AmazonRoute53ReadOnlyAccess","arn:aws:iam::aws:policy/AmazonRoute53FullAccess","arn:aws:iam::387345988065:policy/Route53TenantPolicy","arn:aws:iam::387345988065:policy/AllowTenantExternalDNSUpdates","arn:aws:iam::aws:policy/AmazonRoute53ResolverFullAccess"]
  permissions_boundary  = var.permissions_boundary
  path                  = var.iam_path
  force_detach_policies = true
}


module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.eks.cluster_name
  cluster_version = var.eks.cluster_version
  subnets         = concat(module.vpc.private_subnets,module.vpc.public_subnets)
  enable_irsa     = true
  map_roles = local.map_roles
  cluster_endpoint_private_access = true
  cluster_endpoint_private_access_cidrs = var.eks.private_access_cidrs
  cluster_endpoint_public_access_cidrs  =  var.eks.public_access_cidrs
  tags = {
    Environment = "${var.eks.tags.environment}"
  }
  manage_aws_auth = var.eks.manage_aws_auth
  vpc_id = module.vpc.vpc_id

  depends_on = [aws_iam_role.workers]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "template_file" "launch_template_userdata" {
  template = file("./templates/userdata.sh.tpl")

  vars = {
    cluster_name        = var.eks.cluster_name
    endpoint            = module.eks.cluster_endpoint
    cluster_auth_base64 = module.eks.cluster_certificate_authority_data

    bootstrap_extra_args = ""
    kubelet_extra_args   = ""
  }
}

resource "aws_launch_template" "default" {
  count = length(var.eks.node_group)
  name_prefix            = var.environment
  description            = "${var.eks.cluster_name} Launch-Template"
  update_default_version = true
  key_name = "eks-cluster"
  image_id = var.eks.image_id
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = "${var.eks.node_group[count.index].disk_size}"
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }
  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [module.eks.worker_security_group_id]
  }
  user_data = base64encode(
     data.template_file.launch_template_userdata.rendered,
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      clusterName = var.eks.cluster_name
      environment = var.environment
    }
  }
  tag_specifications {
    resource_type = "volume"
    tags = {
      clusterName = var.eks.cluster_name
      environment = var.environment
    }
  }
  tags = {
    clusterName = var.eks.cluster_name
    environment = var.environment
  }
}

resource "aws_eks_node_group" "workers" {
  count = length(var.eks.node_group)
  node_group_name = "${var.eks.node_group[count.index].name}"
  cluster_name  = var.eks.cluster_name
  node_role_arn = aws_iam_role.workers.arn
  subnet_ids    = module.vpc.private_subnets
  scaling_config {
    desired_size = "${var.eks.node_group[count.index].scaling_config.desired_size}"
    max_size     = "${var.eks.node_group[count.index].scaling_config.max_size}"
    min_size     = "${var.eks.node_group[count.index].scaling_config.min_size}"
  }
  instance_types  = "${var.eks.node_group[count.index].instance_types}"
  launch_template {
    id = aws_launch_template.default[count.index].id
    version = aws_launch_template.default[count.index].latest_version
  }
  tags = {
    "node_group" = "${var.eks.node_group[count.index].tags.environment}"
  }
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config.0.desired_size]
  }
  depends_on = [module.eks]
}


