terraform {
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
    # Kubernetes provider
    kubernetes = {
      source  = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Define the nginx Deployment
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:1.27.2"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Define the nginx Service
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }

  spec {
    selector = {
      app = "nginx"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
