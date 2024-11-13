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
