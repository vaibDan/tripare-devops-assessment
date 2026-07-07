terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend used here so this repo can be reviewed with `terraform plan`
  # and no AWS access of any kind — this assessment explicitly doesn't require
  # real deployment. Each environment gets its own state file so dev and prod
  # never collide. In a real team setup, swap this for `backend "s3"` with a
  # per-environment key + a DynamoDB table for state locking — see
  # backend-dev.hcl for what that config would look like.
  backend "local" {
    path = "terraform-dev.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
}
