# This file is used to create an S3 bucket for Artifactory to store binaries

resource "aws_s3_bucket" "artifactory_binarystore" {
  bucket = "artifactory-${var.region}-${var.env_name}"

  # WARNING: This will force the bucket to be destroyed even if it's not empty
  force_destroy = true

  tags = {
    Group = var.common_tag
  }

  lifecycle {
    prevent_destroy = false
  }
}
