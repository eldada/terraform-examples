# Setup the required variables

# WARNING: CIDR "0.0.0.0/0" is full public access to the cluster, you should use a more restrictive CIDR
variable "region" {
  default = "eu-central-1"
}

variable "cluster_public_access_cidrs" {
  default = "0.0.0.0/0"
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

variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "artifactory"
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
  default     = "Password321"
}

variable "cluster_name" {
  default = "jfrog-eks-cluster"
}

variable "namespace" {
  default = "jfrog"
}
