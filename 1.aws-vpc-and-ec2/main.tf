# Terraform configuration file

# Configure the AWS Provider and set the region
provider "aws" {
  region = "eu-central-1"
}

# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

# Create a subnet
resource "aws_subnet" "main" {
    vpc_id     = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
}

# Create an EC2 instance
resource "aws_instance" "example" {
    ami           = "ami-0084a47cc718c111a"
    instance_type = "t3.micro"
    subnet_id     = aws_subnet.main.id
}
