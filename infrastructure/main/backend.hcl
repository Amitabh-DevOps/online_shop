# Terraform Backend Configuration
# This file is used with: terraform init -backend-config=backend.hcl

bucket         = "github-action-bucket-new"
key            = "terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "github-action-db-new"
encrypt        = true
