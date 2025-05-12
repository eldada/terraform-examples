variable "region" {
  default = "eu-central-1"
}

# WARNING: CIDR "0.0.0.0/0" is full public access to the cluster, you should use a more restrictive CIDR
variable "cluster_public_access_cidrs" {
  default = ["0.0.0.0/0"]
}

variable "env_name" {
  default = "terraform-demo"
}

variable "kubernetes_version" {
  default = "1.32"
}

variable "ec2_capacity_type" {
  default = "ON_DEMAND" # or "SPOT"
}

variable "pool_1_instance_type" {
  default = "t4g.small"
}

variable "pool_2_instance_type" {
  default = "t4g.large"
}

variable "pool_1_max_size" {
  default = 3
}

variable "pool_1_desired_size" {
  default = 1
}

variable "pool_2_max_size" {
  default = 3
}

variable "pool_2_desired_size" {
  default = 1
}
