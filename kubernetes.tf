# Kubernetes provider
# https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster#optional-configure-terraform-kubernetes-provider
# To learn how to schedule deployments and services using the provider, go here: https://learn.hashicorp.com/terraform/kubernetes/deploy-nginx-kubernetes

# The Kubernetes provider is included in this file so the EKS module can complete successfully. Otherwise, it throws an error when creating `kubernetes_config_map.aws_auth`.
# You should **not** schedule deployments and services in this workspace. This keeps workspaces modular (one for provision EKS, another for scheduling Kubernetes resources) as per best practices.

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

provider "helm" {
  kubernetes {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.eks.cluster_name]
      command     = "aws"
    }
  }
}

resource "helm_release" "metric-server" {
  name       = "metric-server"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "kube-system"    

  depends_on = [aws_eks_node_group.workers]
}

resource "null_resource" "metric_server" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
  }
  depends_on = [aws_eks_node_group.workers]
}

resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
   

  values = [templatefile("./valueOverrideFiles/clusterAutoScaler.yaml.tpl", {
    clusterName  = var.eks.cluster_name ,
    serviceAccount  = module.iam_assumable_role_admin.iam_role_arn ,
    awsRegion = var.region
    cloudProvider = "aws"
    fullnameOverride = "cluster-autoscaler"
  })]

  depends_on = [aws_eks_node_group.workers]
}  
 

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  create_namespace = true
  values = [  
    "${file("valueOverrideFiles/prometheus.yaml")}"
  ]      
  depends_on = [aws_eks_node_group.workers]
  set {
    name = "fullnameOverride"
    value = "prometheus"    
  }   
}   


resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  namespace  = "monitoring"

  create_namespace = true   
  depends_on = [aws_eks_node_group.workers]
  set {
    name = "fullnameOverride"
    value = "loki"    
  }  
} 

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring"
  create_namespace = true   
  depends_on = [aws_eks_node_group.workers]

  values = [  
    "${file("valueOverrideFiles/grafanaValues.yaml")}"
  ] 
  
  set {
    name = "fullnameOverride"
    value = "grafana"    
  }  
} 

resource "helm_release" "ingress-nginx" {
  name       = "ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true   
  depends_on = [aws_eks_node_group.workers]
  set {
    name = "fullnameOverride"
    value = "ingress-nginx"    
  }  
} 

resource "helm_release" "cert-manager" {
  name       = "tls"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true 
  
  depends_on = [aws_eks_node_group.workers]
  set {
    name = "version"
    value = "v1.3.1" 
  }
  set {
    name = "installCRDs" 
    value = true
  }
  set {
    name = "fullnameOverride"
    value = "cert-manager"    
  }
}