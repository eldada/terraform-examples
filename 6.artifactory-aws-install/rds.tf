resource "aws_db_subnet_group" "artifactory_subnet_group" {
  name       = "artifactory-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "artifactory-subnet-group"
  }
}

resource "aws_db_instance" "artifactory_db" {
  identifier            = "artifactory-db"
  engine               = "postgres"
  engine_version       = "16.4" # Specify the desired version
  instance_class       = "db.m7g.xlarge" # Change as needed based on expected load
  allocated_storage     = 50 # Minimum is 20 GB for PostgreSQL
  storage_type         = "gp3"
  username             = var.db_username
  password             = var.db_password
  db_name              = "artifactory"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.artifactory_subnet_group.name
  skip_final_snapshot  = true

  tags = {
    Name = "artifactory-db"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = aws_subnet.private[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "artifactory-rds-sg"
  }
}
