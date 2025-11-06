terraform {
  # Use a local backend
  backend "local" {
    path = "./state/terraform.tfstate"
  }

  ## Configure the remote backend (Artifactory)
  ## This will store the state file in Artifactory.
  ## Follow https://jfrog.com/help/r/jfrog-artifactory-documentation/terraform-backend-repository
  # backend "remote" {
  #   hostname = "eldada.jfrog.io"
  #   organization = "terraform-backend"
  #   workspaces {
  #     prefix = "demo-"
  #   }
  # }

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1.0"
    }
  }
}

# Use the local kubectl configuration by helm
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
