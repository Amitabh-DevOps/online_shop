#!/bin/bash

# Script to check available Ubuntu AMIs in eu-west-1
echo "🔍 Checking available Ubuntu AMIs in eu-west-1..."

# Check for Ubuntu 22.04 LTS AMIs
echo "📋 Ubuntu 22.04 LTS AMIs:"
aws ec2 describe-images \
    --region eu-west-1 \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-22.04-lts-amd64-server-*" \
              "Name=state,Values=available" \
    --query 'Images[*].[Name,ImageId,CreationDate]' \
    --output table \
    --max-items 5

echo ""
echo "📋 Ubuntu 20.04 LTS AMIs:"
aws ec2 describe-images \
    --region eu-west-1 \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-20.04-lts-amd64-server-*" \
              "Name=state,Values=available" \
    --query 'Images[*].[Name,ImageId,CreationDate]' \
    --output table \
    --max-items 5

echo ""
echo "📋 Latest Ubuntu AMI (any version):"
aws ec2 describe-images \
    --region eu-west-1 \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*" \
              "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].[Name,ImageId,CreationDate]' \
    --output table
