# Terraform script to deploy Artifactory on the AWS EKS created earlier

data "aws_eks_cluster_auth" "jfrog_cluster" {
  name = module.eks.cluster_name
}

# Configure the Kubernetes provider to use the EKS cluster
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.jfrog_cluster.token
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
}

resource "kubernetes_namespace" "jfrog_namespace" {
  metadata {
    annotations = {
      name = var.namespace
    }

    labels = {
      app = "jfrog"
    }

    name = var.namespace
  }
}

# Configure the Helm provider to use the EKS cluster
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.jfrog_cluster.token
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

# Create a Helm release for Artifactory
resource "helm_release" "artifactory" {
  name       = "artifactory"
  chart      = "jfrog/artifactory"
  version    = var.artifactory_chart_version
  namespace  = var.namespace

  depends_on = [
    aws_db_instance.artifactory_db,
    aws_s3_bucket.artifactory_binarystore,
    module.eks,
    helm_release.metrics_server
  ]

  values = [
    file("${path.module}/artifactory-values.yaml")
  ]

  set {
    name  = "artifactory.persistence.awsS3V3.region"
    value = var.region
  }

  set {
    name  = "artifactory.persistence.awsS3V3.bucketName"
    value = aws_s3_bucket.artifactory_binarystore.bucket
  }

  set {
    name  = "database.url"
    value = "jdbc:postgresql://${aws_db_instance.artifactory_db.endpoint}/${var.db_name}"
  }

  set {
    name  = "database.user"
    value = var.db_username
  }

  set {
    name  = "database.password"
    value = var.db_password
  }

  # Wait for the release to complete deployment
  wait = true
}

data "kubernetes_resources" "nginx_service" {
  api_version    = "v1"
  kind           = "Service"
  namespace      = var.namespace
  label_selector = "component=nginx"

  depends_on = [
    helm_release.artifactory
  ]
}
