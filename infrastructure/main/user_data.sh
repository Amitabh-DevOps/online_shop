#!/bin/bash

# Modern User Data Script for Online Shop Deployment
# This script runs on EC2 instance first boot

set -e

# Logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution at $(date)"

# Update system
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    htop \
    jq \
    awscli

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure firewall
echo "Configuring firewall..."
ufw --force enable
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp

# Create application directory
mkdir -p /opt/online-shop
chown ubuntu:ubuntu /opt/online-shop

# Create systemd service for the application
cat > /etc/systemd/system/online-shop.service << EOF
[Unit]
Description=Online Shop Application
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --name online-shop -p 80:3000 --restart unless-stopped ${docker_image}
ExecStop=/usr/bin/docker stop online-shop
ExecStopPost=/usr/bin/docker rm online-shop
User=ubuntu
Group=docker

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (but don't start it yet - will be started by deployment)
systemctl daemon-reload
systemctl enable online-shop.service

# Create health check script
cat > /opt/online-shop/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for the application

HEALTH_URL="http://localhost"
MAX_ATTEMPTS=30
ATTEMPT=1

echo "Starting health check..."

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
        echo "✅ Application is healthy (attempt $ATTEMPT)"
        exit 0
    else
        echo "⏳ Waiting for application... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep 10
        ATTEMPT=$((ATTEMPT + 1))
    fi
done

echo "❌ Application failed to become healthy after $MAX_ATTEMPTS attempts"
exit 1
EOF

chmod +x /opt/online-shop/health-check.sh
chown ubuntu:ubuntu /opt/online-shop/health-check.sh

# Create deployment script
cat > /opt/online-shop/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script for the application

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

# Run health check
/opt/online-shop/health-check.sh
EOF

chmod +x /opt/online-shop/deploy.sh
chown ubuntu:ubuntu /opt/online-shop/deploy.sh

# Setup log rotation
cat > /etc/logrotate.d/online-shop << EOF
/var/log/user-data.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
EOF

# Final system cleanup
apt-get autoremove -y
apt-get autoclean

echo "User data script completed successfully at $(date)"
echo "System is ready for application deployment"
