variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "tripare-assessment"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16" # distinct range from dev — never overlaps if ever peered
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.101.0/24", "10.1.102.0/24"]
}

variable "container_image" {
  type    = string
  default = "nginx:latest"
}

variable "db_password" {
  description = "Set via TF_VAR_db_password env var — do not put a real value in tfvars"
  type        = string
  sensitive   = true
  default     = "changeme-placeholder"
}

# --- prod-specific sizing / retention: larger and more durable than dev ---
variable "task_cpu" {
  type    = string
  default = "512"
}

variable "task_memory" {
  type    = string
  default = "1024"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_backup_retention_period" {
  type    = number
  default = 7
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "multi_az" {
  type    = bool
  default = true
}
