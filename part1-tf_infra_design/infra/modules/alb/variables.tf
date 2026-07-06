variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  description = "Port the ECS task listens on, ALB forwards traffic here"
  type        = number
  default     = 80
}
