# Configure the Helm provider and create a Helm release
# Define the required Helm provider
terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create a Helm release for Artifactory
resource "helm_release" "artifactory" {
  name       = "artifactory"
  repository = "https://charts.jfrog.io"
  chart      = "artifactory"

  values = [
    file("${path.module}/artifactory-values.yaml")
  ]
}
