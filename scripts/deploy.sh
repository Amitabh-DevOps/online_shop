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

# Wait for user data to complete
echo "⏳ Waiting for instance initialization to complete..."
for i in {1..20}; do
    if ssh $SSH_OPTS ubuntu@$EC2_HOST "test -f /var/log/user-data.log && grep -q 'User data script completed successfully' /var/log/user-data.log" 2>/dev/null; then
        echo "✅ Instance initialization completed"
        break
    else
        echo "Attempt $i/20: Waiting for user data to complete..."
        sleep 15
    fi
    
    if [ $i -eq 20 ]; then
        echo "⚠️  User data may not have completed, proceeding with deployment..."
        break
    fi
done

# Create deployment script on the fly if it doesn't exist
echo "📦 Setting up deployment environment..."
ssh $SSH_OPTS ubuntu@$EC2_HOST << 'EOF'
# Ensure Docker is available
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ubuntu
    # Re-login to apply group changes
    newgrp docker
fi

# Create deployment directory
sudo mkdir -p /opt/online-shop
sudo chown ubuntu:ubuntu /opt/online-shop

# Create deployment script
cat > /opt/online-shop/deploy.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

DOCKER_IMAGE="$1"

if [ -z "$DOCKER_IMAGE" ]; then
    echo "Usage: $0 <docker-image>"
    exit 1
fi

echo "Deploying $DOCKER_IMAGE..."

# Stop existing container
docker stop online-shop || true
docker rm online-shop || true

# Pull latest image
docker pull "$DOCKER_IMAGE"

# Run new container
docker run -d \
    --name online-shop \
    -p 80:3000 \
    --restart unless-stopped \
    "$DOCKER_IMAGE"

echo "Deployment completed successfully!"
DEPLOY_SCRIPT

chmod +x /opt/online-shop/deploy.sh
EOF

# Deploy the application
echo "🚀 Deploying application..."
ssh $SSH_OPTS ubuntu@$EC2_HOST "/opt/online-shop/deploy.sh '$DOCKER_IMAGE'"

# Verify deployment
echo "🔍 Verifying deployment..."
sleep 15

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

# Show container status for debugging
echo "📊 Container status:"
ssh $SSH_OPTS ubuntu@$EC2_HOST "docker ps -a | grep online-shop || echo 'No container found'"

exit 1
