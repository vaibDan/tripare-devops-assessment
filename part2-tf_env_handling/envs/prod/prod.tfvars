environment = "prod"
aws_region  = "ap-south-1"

# --- Networking: separate CIDR range from dev ---
vpc_cidr             = "10.1.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24"]

# --- App sizing: bigger than dev, real traffic expected ---
container_image = "nginx:latest"
task_cpu        = "512"
task_memory     = "1024"

# --- DB: bigger instance, longer retention, deletion protection ON ---
# Prod data must survive an accidental `terraform destroy` and a longer
# backup window matters because real customer data can't just be reseeded
# the way dev data can.
db_instance_class          = "db.t3.medium"
db_backup_retention_period = 7
db_deletion_protection     = true
multi_az                   = true
