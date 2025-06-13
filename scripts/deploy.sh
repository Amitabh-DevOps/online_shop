#!/bin/bash

# Modern Deployment Script for Online Shop
# This script deploys the application to EC2 instance

set -e

# Configuration
DOCKER_IMAGE="$1"
EC2_HOST="$2"
SSH_KEY="$3"

# Validation
if [ -z "$DOCKER_IMAGE" ] || [ -z "$EC2_HOST" ] || [ -z "$SSH_KEY" ]; then
    echo "Usage: $0 <docker-image> <ec2-host> <ssh-key-path>"
    echo "Example: $0 username/online-shop:latest 1.2.3.4 ~/.ssh/key.pem"
    exit 1
fi

echo "🚀 Starting deployment..."
echo "Docker Image: $DOCKER_IMAGE"
echo "EC2 Host: $EC2_HOST"
echo "SSH Key: $SSH_KEY"

# SSH options
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Wait for EC2 to be ready
echo "⏳ Waiting for EC2 instance to be ready..."
for i in {1..30}; do
    if ssh $SSH_OPTS ubuntu@$EC2_HOST "echo 'SSH connection successful'" 2>/dev/null; then
        echo "✅ SSH connection established"
        break
    else
        echo "Attempt $i/30: Waiting for SSH..."
        sleep 10
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Failed to establish SSH connection after 30 attempts"
        exit 1
    fi
done

# Deploy the application
echo "📦 Deploying application..."
ssh $SSH_OPTS ubuntu@$EC2_HOST "sudo /opt/online-shop/deploy.sh '$DOCKER_IMAGE'"

# Verify deployment
echo "🔍 Verifying deployment..."
sleep 10

# Health check
for i in {1..10}; do
    if curl -f -s "http://$EC2_HOST" > /dev/null; then
        echo "✅ Application is healthy and accessible!"
        echo "🌐 Application URL: http://$EC2_HOST"
        exit 0
    else
        echo "Health check attempt $i/10..."
        sleep 10
    fi
done

echo "⚠️  Deployment completed but health check failed"
echo "Please check the application manually at: http://$EC2_HOST"
exit 1
