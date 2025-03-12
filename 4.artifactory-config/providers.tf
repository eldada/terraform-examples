# Define the required JFrog Artifactory provider
terraform {
  # Use a local backend
  backend "local" {
    path = "./state/terraform.tfstate"
  }

  required_providers {
    artifactory = {
      source  = "jfrog/artifactory"
    }
  }
}

# Configure the JFrog Artifactory server and access
provider "artifactory" {
  url           = "${var.artifactory_url}/artifactory"
  access_token  = var.artifactory_access_token
}
