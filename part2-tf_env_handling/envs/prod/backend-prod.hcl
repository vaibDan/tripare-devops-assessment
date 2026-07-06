# Example backend config for a real team setup — NOT used by default.
# Same rationale as backend-dev.hcl. Note the different `key` — this is what
# actually keeps dev and prod state isolated in a shared S3 bucket.

bucket         = "tripare-terraform-state"
key            = "prod/terraform.tfstate"
region         = "ap-south-1"
dynamodb_table = "tripare-terraform-locks"
encrypt        = true
