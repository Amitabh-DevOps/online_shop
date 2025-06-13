#!/bin/bash

# Backend Setup Script
# This script creates the S3 bucket and DynamoDB table for Terraform state

set -e

# Configuration
STATE_BUCKET_NAME="$1"
DYNAMODB_TABLE_NAME="$2"
AWS_REGION="${3:-eu-west-1}"

# Validation
if [ -z "$STATE_BUCKET_NAME" ] || [ -z "$DYNAMODB_TABLE_NAME" ]; then
    echo "Usage: $0 <state-bucket-name> <dynamodb-table-name> [aws-region]"
    echo "Example: $0 my-terraform-state my-terraform-locks eu-west-1"
    exit 1
fi

echo "🏗️  Setting up Terraform backend..."
echo "S3 Bucket: $STATE_BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE_NAME"
echo "AWS Region: $AWS_REGION"

# Navigate to backend directory
cd "$(dirname "$0")/../infrastructure/backend"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Plan the backend creation
echo "📋 Planning backend infrastructure..."
terraform plan \
    -var="state_bucket_name=$STATE_BUCKET_NAME" \
    -var="dynamodb_table_name=$DYNAMODB_TABLE_NAME" \
    -var="aws_region=$AWS_REGION"

# Apply the backend configuration
echo "🚀 Creating backend infrastructure..."
terraform apply -auto-approve \
    -var="state_bucket_name=$STATE_BUCKET_NAME" \
    -var="dynamodb_table_name=$DYNAMODB_TABLE_NAME" \
    -var="aws_region=$AWS_REGION"

echo "✅ Backend infrastructure created successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Update your main Terraform configuration to use this backend"
echo "2. Run 'terraform init' in your main infrastructure directory"
echo ""
echo "Backend configuration:"
echo "  bucket         = \"$STATE_BUCKET_NAME\""
echo "  key            = \"terraform.tfstate\""
echo "  region         = \"$AWS_REGION\""
echo "  dynamodb_table = \"$DYNAMODB_TABLE_NAME\""
