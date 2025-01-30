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

## Until sizing specs are part of the jfrog-platform chart, we pull them from the individual charts that are inside the platform chart
# Fetch the JFrog Platform Helm chart and untar it to the current directory so we can use the sizing files to create the final values files
resource "null_resource" "fetch_platform_chart" {
  provisioner "local-exec" {
    command = "rm -rf jfrog-platform-*.tgz"
  }
  provisioner "local-exec" {
    command = "helm fetch jfrog-platform --version ${var.jfrog_platform_chart_version} --repo https://charts.jfrog.io --untar"
  }
}

################### Artifactory sizing
## Prepare the final values files for the JFrog Platform sizing
data "local_file" "artifactory_sizing" {
  filename = "${path.module}/jfrog-platform/charts/artifactory/sizing/artifactory-${var.sizing}.yaml"
  depends_on = [null_resource.fetch_platform_chart]
}

# Inject two spaces before all lines and load into a variable
locals {
  indented_artifactory_sizing = join("\n", [for line in split("\n", data.local_file.artifactory_sizing.content) : "  ${line}"])
}

# Create the new artifactory sizing YAML string
locals {
  new_artifactory_sizing = <<-EOT
  artifactory:
  ${local.indented_artifactory_sizing}
  EOT
}

# Write the new Artifactory YAML to a file
resource "local_file" "new_artifactory_sizing" {
  filename = "${path.module}/jfrog-artifactory-${var.sizing}-adjusted.yaml"
  content  = trimspace(local.new_artifactory_sizing)
}

################### Xray sizing
## Prepare the final values files for the JFrog Platform sizing
data "local_file" "xray_sizing" {
  filename = "${path.module}/jfrog-platform/charts/xray/sizing/xray-${var.sizing}.yaml"
  depends_on = [null_resource.fetch_platform_chart]
}

# Inject two spaces before all lines and load into a variable
locals {
  indented_xray_sizing = join("\n", [for line in split("\n", data.local_file.xray_sizing.content) : "  ${line}"])
}

# Create the new Xray sizing YAML string
locals {
  new_xray_sizing = <<-EOT
  xray:
  ${local.indented_xray_sizing}
  EOT
}

# Write the new Xray YAML to a file
resource "local_file" "new_xray_sizing" {
  filename = "${path.module}/jfrog-xray-${var.sizing}-adjusted.yaml"
  content  = trimspace(local.new_xray_sizing)
}

# Create an empty artifactory-license.yaml if missing
resource "local_file" "empty_license" {
  count = fileexists("${path.module}/artifactory-license.yaml") ? 0 : 1
  filename = "${path.module}/artifactory-license.yaml"
  content = "## Empty file to satisfy Helm requirements"
}

# Set the cache-fs-size based on the sizing variable to 80% of the disk size
locals {
  cache-fs-size = (var.sizing == "large"  ? var.artifactory_disk_size_large * 0.8 :
                  var.sizing == "xlarge"  ? var.artifactory_disk_size_large * 0.8 :
                  var.sizing == "2xlarge" ? var.artifactory_disk_size_large * 0.8 :
                  var.artifactory_disk_size_default * 0.8)
}

# Write the artifactory-custom.yaml file with the variables needed
resource "local_file" "jfrog_platform_values" {
  content  = <<-EOT
  artifactory:
    artifactory:
      persistence:
        maxCacheSize: "${local.cache-fs-size}000000000"
        awsS3V3:
          region: "${var.region}"
          bucketName: "artifactory-${var.region}-${var.s3_bucket_name_suffix}"

    database:
      url: "jdbc:postgresql://${aws_db_instance.artifactory_db.endpoint}/${var.artifactory_db_name}?sslmode=require"
      user: "${var.artifactory_db_username}"
      password: "${var.artifactory_db_password}"

  xray:
    database:
      url: "postgres://${aws_db_instance.xray_db.endpoint}/${var.xray_db_name}?sslmode=require"
      user: "${var.xray_db_username}"
      password: "${var.xray_db_password}"

  EOT
  filename = "${path.module}/jfrog-custom.yaml"

  depends_on = [
    aws_db_instance.artifactory_db,
    aws_db_instance.xray_db,
    aws_s3_bucket.artifactory_binarystore,
    module.eks,
    helm_release.metrics_server
  ]
}

## Create a Helm release for the JFrog Platform
## Leaving this as an example of how to deploy the JFrog Platform with Helm using multiple values files

# resource "kubernetes_namespace" "jfrog_namespace" {
#   metadata {
#     annotations = {
#       name = var.namespace
#     }
#
#     labels = {
#       app = "jfrog"
#     }
#
#     name = var.namespace
#   }
# }
#
# # Create a Helm release for the JFrog Platform
# resource "helm_release" "jfrog_platform" {
#   name       = var.namespace
#   chart      = "jfrog/jfrog-platform"
#   version    = var.jfrog_platform_chart_version
#   namespace  = var.namespace
#
#   depends_on = [
#     aws_db_instance.artifactory_db,
#     aws_s3_bucket.artifactory_binarystore,
#     module.eks,
#     helm_release.metrics_server
#   ]
#
#   values = [
#     file("${path.module}/jfrog-values.yaml")
#   ]
#
#   set {
#     name  = "artifactory.artifactory.persistence.awsS3V3.region"
#     value = var.region
#   }
#
#   set {
#     name  = "artifactory.artifactory.persistence.awsS3V3.bucketName"
#     value = aws_s3_bucket.artifactory_binarystore.bucket
#   }
#
#   set {
#     name  = "artifactory.database.url"
#     value = "jdbc:postgresql://${aws_db_instance.artifactory_db.endpoint}/${var.artifactory_db_name}"
#   }
#
#   set {
#     name  = "artifactory.database.user"
#     value = var.artifactory_db_username
#   }
#
#   set {
#     name  = "artifactory.database.password"
#     value = var.artifactory_db_password
#   }
#
#   set {
#     name  = "xray.database.url"
#     value = "postgres://${aws_db_instance.xray_db.endpoint}/${var.xray_db_name}?sslmode="
#   }
#
#   set {
#     name  = "xray.database.user"
#     value = var.xray_db_username
#   }
#
#   set {
#     name  = "xray.database.password"
#     value = var.xray_db_password
#   }
#
#   # Wait for the release to complete deployment
#   wait = true
#
#   # Increase the timeout to 10 minutes for the JFrog Platform to deploy
#   timeout = 600
# }
#
# data "kubernetes_resources" "nginx_service" {
#   api_version    = "v1"
#   kind           = "Service"
#   namespace      = var.namespace
#   label_selector = "component=nginx"
#
#   depends_on = [
#     helm_release.jfrog_platform
#   ]
# }
