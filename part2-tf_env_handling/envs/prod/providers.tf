terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Same rationale as dev (see envs/dev/providers.tf): local backend so this
  # can be reviewed with plan-only, no live AWS access required. Prod gets
  # its own state file so it can never collide with or be overwritten by dev.
  backend "local" {
    path = "terraform-prod.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
}
