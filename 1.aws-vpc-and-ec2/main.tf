# Create a VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = var.vpc_name
    }
}

# Create a subnet
resource "aws_subnet" "main" {
    vpc_id     = aws_vpc.main.id
    cidr_block = var.vpc_cidr

    tags = {
        Name = var.vpc_name
    }
}

# Create an EC2 instance
resource "aws_instance" "example" {
    ami           = var.ami_id
    instance_type = var.instance_type
    subnet_id     = aws_subnet.main.id

    tags = {
        Name = var.vpc_name
    }
}
