# Define the required JFrog Artifactory provider
terraform {
  # Use a local backend
  backend "local" {
    path = "./state/terraform.tfstate"
  }

  required_providers {
    artifactory = {
      source  = "jfrog/artifactory"
      version = "~> 12.10.1"
    }
    platform = {
      source  = "jfrog/platform"
      version = "~> 2.2.6"
    }
  }
}

# Configure the JFrog Artifactory and Platform providers
provider "artifactory" {
  url           = "${var.artifactory_url}/artifactory"
  access_token  = var.artifactory_access_token
}

provider "platform" {
  url           = "${var.artifactory_url}"
  access_token  = var.artifactory_access_token
}
