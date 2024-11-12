# Setup the providers

terraform {
  required_providers {
    # Kubernetes provider
    aws = {
      source  = "hashicorp/aws"
    }
    # Kubernetes provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
    # Helm provider
    helm = {
      source  = "hashicorp/helm"
    }
  }
}

provider "aws" {
  region = var.region
}
