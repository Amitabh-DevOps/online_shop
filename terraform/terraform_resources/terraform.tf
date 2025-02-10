terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.86.0"
    }
  }

  backend "s3" {
    bucket = "github-actions-bucket"
    key = "terraform.tfstate"
    region = "eu-west-1"
    dynamodb_table = "github-actions-db"
  }
  
}
# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}