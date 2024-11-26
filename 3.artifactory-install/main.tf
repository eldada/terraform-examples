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

# Create a Helm release for Artifactory
resource "helm_release" "artifactory" {
  name        = "artifactory"
  repository  = "https://charts.jfrog.io"
  chart       = "artifactory"
  version     = "107.98.9"

  values = [
    file("${path.module}/artifactory-values.yaml")
  ]
}
