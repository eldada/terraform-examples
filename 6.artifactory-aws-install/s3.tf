# This file is used to create an S3 bucket for Artifactory to store binaries

resource "aws_s3_bucket" "artifactory_binarystore" {
  bucket = "artifactory-${var.region}-eldada-example"

  # WARNING: This will force the bucket to be destroyed even if it's not empty
  force_destroy = true

  tags = {
    Name        = "artifactory-binarystore"
  }

  lifecycle {
    prevent_destroy = false
  }
}
