locals {
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler"
  ec2_principal = "ec2.${data.aws_partition.current.dns_suffix}"
  sts_principal = "sts.${data.aws_partition.current.dns_suffix}"
  map_roles = [{
    rolearn  = aws_iam_role.workers.arn
    username = "system:node:{{EC2PrivateDNSName}}"
    groups   = ["system:bootstrappers","system:nodes"]
  }]
}