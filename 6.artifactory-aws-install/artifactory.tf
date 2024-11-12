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

resource "kubernetes_secret" "artifactory_db_credentials" {
  metadata {
    name      = "artifactory-db-credentials"
    namespace = var.namespace
  }

  data = {
    url      = "jdbc:postgresql://${aws_db_instance.artifactory_db.endpoint}/${aws_db_instance.artifactory_db.db_name}"
    username = var.db_username
    password = var.db_password
  }

  type = "Opaque"  # Opaque is a standard type for secrets
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
  version    = "107.98.7"
  namespace  = var.namespace

  depends_on = [
    aws_db_instance.artifactory_db,
    aws_s3_bucket.artifactory_binarystore,
    kubernetes_secret.artifactory_db_credentials,
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
    value = "jdbc:postgresql://${aws_db_instance.artifactory_db.endpoint}/${aws_db_instance.artifactory_db.db_name}"
  }

  set {
    name  = "database.user"
    value = var.db_username
  }

  set {
    name  = "database.password"
    value = var.db_password
  }

  # Don't wait for the release to complete deployment
  wait = false
}
