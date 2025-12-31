# Install the metrics server if the deploy_metrics_server variable is true
resource "helm_release" "metrics_server" {
  count = var.deploy_metrics_server ? 1 : 0

  name       = "metrics-server"
  chart      = "metrics-server"
  namespace  = "kube-system"

  # Repository to install the chart from
  repository = "https://kubernetes-sigs.github.io/metrics-server/"

  # Don't wait for the release to complete deployment
  wait = false

  # Ensure EKS cluster and compute resources are ready before installing
  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.main,
    aws_eks_fargate_profile.main
  ]
}
