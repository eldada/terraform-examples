# Setup the providers
terraform {
  # Use a local backend
  backend "local" {
    path = "./state/terraform.tfstate"
  }

  ## Configure the remote backend (Artifactory)
  ## This will store the state file in Artifactory.
  ## Follow https://jfrog.com/help/r/jfrog-artifactory-documentation/terraform-backend-repository
  ## Create a new terraform workspace in Artifactory named "jfrog"
  # backend "remote" {
  #   hostname = "eldada.jfrog.io"
  #   organization = "terraform-backend"
  #   workspaces {
  #     prefix = "jfrog"
  #   }
  # }

  required_providers {
    local = {
      source  = "hashicorp/local"
    }
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
