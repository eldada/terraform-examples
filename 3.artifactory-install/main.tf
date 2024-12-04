# Configure the Helm provider and create a Helm release
# Define the required Helm provider
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
  }
}

# Use the local Kubernetes configuration
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create an empty artifactory-license.yaml if missing
resource "local_file" "empty_license" {
  count = fileexists("${path.module}/artifactory-license.yaml") ? 0 : 1
  filename = "${path.module}/artifactory-license.yaml"
  content = "## Empty file to satisfy Helm requirements"
}

# Create a Helm release for Artifactory (including the license)
resource "helm_release" "artifactory" {
  name        = "artifactory"
  repository  = "https://charts.jfrog.io"
  chart       = "artifactory"
  version     = "107.98.9"

  depends_on = [
    local_file.empty_license
  ]

  values = [
    file("${path.module}/artifactory-values.yaml"),
    file("${path.module}/artifactory-license.yaml")
  ]
}
