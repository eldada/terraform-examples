terraform {
  # Use a local backend
  backend "local" {
    path = "./state/terraform.tfstate"
  }

  ## Configure the remote backend (Artifactory)
  ## This will store the state file in Artifactory.
  ## Follow https://docs.jfrog.com/artifactory/docs/terraform-opentofu-and-terraform-backend-repositories
  # backend "remote" {
  #   hostname = "eldada.jfrog.io"
  #   organization = "terraform-backend"
  #   workspaces {
  #     prefix = "demo-"
  #   }
  # }

  required_providers {
    # Kubernetes provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
  }
}

# Use the current configured kubectl context
provider "kubernetes" {
  config_path = "~/.kube/config"
}
