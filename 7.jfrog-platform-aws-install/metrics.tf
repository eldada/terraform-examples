provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.jfrog_cluster.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

# Install the metrics server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  # version    = "3.12.2"
  namespace  = "kube-system"

  # Repository to install the chart from
  repository = "https://kubernetes-sigs.github.io/metrics-server/"

  # Don't wait for the release to complete deployment
  wait = false
}
