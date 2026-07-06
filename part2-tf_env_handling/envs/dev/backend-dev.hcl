# Example backend config for a real team setup — NOT used by default.
# This assessment uses `backend "local"` (see providers.tf) so it can be
# reviewed with `terraform init && terraform plan` without needing AWS
# credentials for a bucket only the candidate has access to.
#
# To switch to this in a real environment:
#   1. Remove the `backend "local"` block from providers.tf, replace with
#      `backend "s3" {}` (empty — config supplied via -backend-config)
#   2. Create the bucket + DynamoDB table once, out of band
#   3. terraform init -backend-config=backend-dev.hcl -migrate-state

bucket         = "tripare-terraform-state"
key            = "dev/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "tripare-terraform-locks"
encrypt        = true
