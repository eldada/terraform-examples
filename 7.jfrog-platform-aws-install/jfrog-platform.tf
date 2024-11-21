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

# Create a Helm release for the JFrog Platform
resource "helm_release" "jfrog_platform" {
  name       = var.namespace
  chart      = "jfrog/jfrog-platform"
  version    = var.jfrog_platform_chart_version
  namespace  = var.namespace

  depends_on = [
    aws_db_instance.artifactory_db,
    aws_s3_bucket.artifactory_binarystore,
    helm_release.metrics_server
  ]

  values = [
    file("${path.module}/jfrog-values.yaml")
  ]

  set {
    name  = "artifactory.artifactory.persistence.awsS3V3.region"
    value = var.region
  }

  set {
    name  = "artifactory.artifactory.persistence.awsS3V3.bucketName"
    value = aws_s3_bucket.artifactory_binarystore.bucket
  }

  set {
    name  = "artifactory.database.url"
    value = "jdbc:postgresql://${aws_db_instance.artifactory_db.endpoint}/${var.artifactory_db_name}"
  }

  set {
    name  = "artifactory.database.user"
    value = var.artifactory_db_username
  }

  set {
    name  = "artifactory.database.password"
    value = var.artifactory_db_password
  }

  set {
    name  = "xray.database.url"
    value = "postgres://${aws_db_instance.xray_db.endpoint}/${var.xray_db_name}?sslmode="
  }

  set {
    name  = "xray.database.user"
    value = var.xray_db_username
  }

  set {
    name  = "xray.database.password"
    value = var.xray_db_password
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
    helm_release.jfrog_platform
  ]
}
