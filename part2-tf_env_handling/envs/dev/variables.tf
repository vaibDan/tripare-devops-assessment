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
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
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

# --- dev-specific sizing / retention (Part 2 will contrast this with prod) ---
variable "task_cpu" {
  type    = string
  default = "256"
}

variable "task_memory" {
  type    = string
  default = "512"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_backup_retention_period" {
  type    = number
  default = 1
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "multi_az" {
  type    = bool
  default = false
}
