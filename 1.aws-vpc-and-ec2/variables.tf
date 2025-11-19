# Region
variable "region" {
  default = "eu-central-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc_name" {
  default = "example-vpc"
}

variable "ami_id" {
  default = "ami-0084a47cc718c111a"
}

variable "instance_type" {
  default = "t3.micro"
}

