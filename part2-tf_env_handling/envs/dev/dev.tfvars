environment = "dev"
aws_region  = "ap-south-1"

# --- Networking ---
vpc_cidr             = "10.0.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

# --- App sizing: small, since dev doesn't need to handle real traffic ---
container_image = "nginx:latest"
task_cpu        = "256"
task_memory     = "512"

# --- DB: small instance, short retention, no deletion protection ---
# Dev databases get torn down often — deletion_protection=true would just get
# in the way, and a 1-day backup window is plenty since dev data is disposable.
db_instance_class          = "db.t3.micro"
db_backup_retention_period = 1
db_deletion_protection     = false
multi_az                   = false
