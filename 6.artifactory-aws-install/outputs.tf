output "_01_region" {
  description = "AWS region"
  value       = var.region
}

output "_02_eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "_03_eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "_04_resources_tag" {
  description = "The common tag applied on all resources"
  value       = "Group: ${var.common_tag}"
}

# Output the command to configure kubectl config to the newly created EKS cluster
output "_05_setting_cluster_kubectl_context" {
  description = "Connect kubectl to Kubernetes Cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "_06_artifactory_url" {
  description = "The URL of the load balancer for Artifactory"
  value = "https://${data.kubernetes_resources.nginx_service.objects[0].status.loadBalancer.ingress[0].hostname}"
}
