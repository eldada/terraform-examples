# This file creates an RDS instance for the Artifactory database

resource "aws_db_subnet_group" "artifactory_subnet_group" {
  name       = "artifactory-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Group = var.common_tag
  }
}

resource "aws_db_instance" "artifactory_db" {
  identifier             = "artifactory-db"
  engine                 = "postgres"
  engine_version         = "16.4" # Specify the desired version
  instance_class         = "db.m7g.large" # Change as needed based on expected load

  storage_type           = "gp3"        # Using gp3 for storage type
  allocated_storage      = 50          # Set desired storage size in GB
  max_allocated_storage  = 100          # Set maximum size for storage autoscaling (optional)

  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.artifactory_subnet_group.name
  skip_final_snapshot    = true

  tags = {
    Group = var.common_tag
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Group = var.common_tag
  }
}
