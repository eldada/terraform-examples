# This file creates an RDS instance for the Artifactory database

resource "aws_db_subnet_group" "artifactory_subnet_group" {
  name       = "artifactory-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Group = var.common_tag
  }
}

resource "aws_db_instance" "artifactory_db" {
  identifier       = "artifactory-db"
  engine           = "postgres"
  engine_version   = "16.4" # Specify the desired version

  # Set the instance class based on the sizing variable
  instance_class = (
      var.sizing == "medium"  ? "db.m7g.4xlarge" :
      var.sizing == "large"   ? "db.m7g.8xlarge" :
      var.sizing == "xlarge"  ? "db.m7g.12xlarge" :
      var.sizing == "2xlarge" ? "db.m7g.16xlarge" :
      "db.m7g.2xlarge"
  )

  storage_type      = "gp3"        # Using gp3 for storage type
  allocated_storage = (
      var.sizing == "medium"  ? "250" :
      var.sizing == "large"   ? "500" :
      var.sizing == "xlarge"  ? "1000" :
      var.sizing == "2xlarge" ? "1500" :
      "50"
  )

  max_allocated_storage  = 2000          # Set maximum size for storage autoscaling (optional)
  storage_encrypted      = true

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
