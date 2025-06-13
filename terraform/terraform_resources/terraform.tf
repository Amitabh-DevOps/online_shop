terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "github-actions-buckets-new"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "github-actions-dbs-new"
    encrypt        = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "online-shop"
      ManagedBy   = "terraform"
    }
  }
}
