terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend for this assessment. In a real team setup this would be
  # an S3 backend with DynamoDB state locking — swapped in per-environment.
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  # These three flags let `terraform plan` run for review purposes even
  # without live AWS credentials configured locally, since this assessment
  # explicitly does not require an actual deployment.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
}
