output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "resources_tag" {
  description = "The common tag applied on all resources"
  value       = "Group: ${var.common_tag}"
}

# Output the command to configure kubectl config to the newly created EKS cluster
output "x_cluster_kubectl_context" {
  description = "Connect kubectl to Kubernetes Cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "x_artifactory_url" {
  description = "The URL of the load balancer for Artifactory"
  value = "https://${data.kubernetes_resources.nginx_service.objects[0].status.loadBalancer.ingress[0].hostname}"
}
