# --- RDS Security Group: only accepts connections from ECS tasks ---
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow inbound DB traffic only from the ECS security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "From ECS tasks only"
    from_port       = var.engine == "postgres" ? 5432 : 3306
    to_port         = var.engine == "postgres" ? 5432 : 3306
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id] # <-- SG reference, not a CIDR block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
  }
}

# --- DB subnet group: tells RDS which (private) subnets it may live in ---
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false # <-- this is what makes RDS "private"

  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  multi_az                = var.multi_az
  skip_final_snapshot     = !var.deletion_protection # dev: skip snapshot on destroy; prod: keep one

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
  }
}
