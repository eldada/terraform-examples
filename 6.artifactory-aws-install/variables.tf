# Setup the required variables

variable "region" {
  default = "eu-central-1"
}

# WARNING: CIDR "0.0.0.0/0" is full public access to the cluster. You should use a more restrictive CIDR
variable "cluster_public_access_cidrs" {
  default = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "db_name" {
  description = "The database name"
  default     = "artifactory"
}

variable "db_username" {
  description = "The username for the database"
  default     = "artifactory"
}

variable "db_password" {
  description = "The password for the database"
  sensitive   = true
  default     = "Password321"
}

variable "cluster_name" {
  default = "jfrog-eks-cluster"
}

variable "namespace" {
  default = "jfrog"
}

variable "artifactory_chart_version" {
  default = "107.98.7"
}

variable "common_tag" {
  description = "The 'Group' tag to apply to all resources"
  default = "jfrog"
}

variable "sizing" {
  type        = string
  description = "The sizing templates for the infrastructure and Artifactory"
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large", "xlarge", "2xlarge"], var.sizing)
    error_message = "Invlid sizing set. Supported sizings are: 'small', 'medium', 'large', 'xlarge' or '2xlarge'"
  }
}
