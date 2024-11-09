# This file is used to create an S3 bucket for Artifactory to store binaries

resource "aws_s3_bucket" "artifactory_binarystore" {
  bucket = "artifactory-${var.region}-eldada-example"

  tags = {
    Name        = "artifactory-binarystore"
    Environment = "production"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# resource "aws_s3_bucket_acl" "acl1" {
#   bucket = aws_s3_bucket.artifactory_binarystore.bucket
#   acl    = "private"
# }
