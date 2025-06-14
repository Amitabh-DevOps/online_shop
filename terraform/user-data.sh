#!/bin/bash

# ============================================================================
# User Data Script for Online Shop EC2 Instance
# ============================================================================

set -e

# Variables from Terraform
DOCKER_IMAGE="${docker_image}"
DOCKERHUB_USERNAME="${dockerhub_username}"
PROJECT_NAME="${project_name}"
AWS_REGION="${aws_region}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "Starting user data script execution..."

# ============================================================================
# System Updates and Basic Setup
# ============================================================================

log "Updating system packages..."
yum update -y

log "Installing essential packages..."
yum install -y \
    curl \
    wget \
    git \
    htop \
    unzip \
    jq \
    awscli

# ============================================================================
# Docker Installation and Configuration
# ============================================================================

log "Installing Docker..."
yum install -y docker

log "Starting and enabling Docker service..."
systemctl start docker
systemctl enable docker

log "Adding ec2-user to docker group..."
usermod -a -G docker ec2-user

# ============================================================================
# CloudWatch Agent Installation (Optional)
# ============================================================================

log "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "/aws/ec2/${project_name}",
                        "log_stream_name": "{instance_id}/user-data.log"
                    },
                    {
                        "file_path": "/var/log/docker.log",
                        "log_group_name": "/aws/ec2/${project_name}",
                        "log_stream_name": "{instance_id}/docker.log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "AWS/EC2/Custom",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

log "Starting CloudWatch agent..."
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# ============================================================================
# Application Deployment Preparation
# ============================================================================

log "Creating application directory..."
mkdir -p /opt/online-shop
chown ec2-user:ec2-user /opt/online-shop

# Create deployment script
cat > /opt/online-shop/deploy.sh << 'EOF'
#!/bin/bash

set -e

DOCKER_IMAGE="$1"
CONTAINER_NAME="online-shop"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/docker.log
}

log "Starting deployment of $DOCKER_IMAGE..."

# Stop and remove existing container
log "Stopping existing container..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

# Pull latest image
log "Pulling Docker image: $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE

# Run new container
log "Starting new container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p 80:3000 \
    -e NODE_ENV=production \
    $DOCKER_IMAGE

# Health check
log "Performing health check..."
sleep 30
if curl -f -s http://localhost > /dev/null; then
    log "✅ Application is healthy and responding!"
else
    log "❌ Application health check failed!"
    exit 1
fi

log "✅ Deployment completed successfully!"
EOF

chmod +x /opt/online-shop/deploy.sh
chown ec2-user:ec2-user /opt/online-shop/deploy.sh

# ============================================================================
# Nginx Installation and Configuration (Optional Reverse Proxy)
# ============================================================================

log "Installing Nginx..."
yum install -y nginx

# Create Nginx configuration
cat > /etc/nginx/conf.d/online-shop.conf << EOF
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

log "Starting and enabling Nginx..."
systemctl start nginx
systemctl enable nginx

# ============================================================================
# System Monitoring and Maintenance
# ============================================================================

# Create system monitoring script
cat > /opt/online-shop/monitor.sh << 'EOF'
#!/bin/bash

# System monitoring script
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/monitor.log
}

# Check Docker container status
if ! docker ps | grep -q online-shop; then
    log "⚠️ Online Shop container is not running!"
    # Attempt to restart
    /opt/online-shop/deploy.sh "$DOCKER_IMAGE" || log "❌ Failed to restart container"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    log "⚠️ Disk usage is high: $DISK_USAGE%"
fi

# Check memory usage
MEM_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
    log "⚠️ Memory usage is high: $MEM_USAGE%"
fi

log "✅ System monitoring check completed"
EOF

chmod +x /opt/online-shop/monitor.sh
chown ec2-user:ec2-user /opt/online-shop/monitor.sh

# Add monitoring to crontab
echo "*/5 * * * * /opt/online-shop/monitor.sh" | crontab -u ec2-user -

# ============================================================================
# Firewall Configuration
# ============================================================================

log "Configuring firewall..."
# Amazon Linux 2023 uses firewalld by default
systemctl start firewalld
systemctl enable firewalld

# Allow HTTP, HTTPS, and SSH
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# ============================================================================
# Final Setup and Cleanup
# ============================================================================

log "Setting up log rotation..."
cat > /etc/logrotate.d/online-shop << EOF
/var/log/user-data.log
/var/log/docker.log
/var/log/monitor.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 ec2-user ec2-user
}
EOF

log "Creating system info script..."
cat > /opt/online-shop/system-info.sh << 'EOF'
#!/bin/bash

echo "=== Online Shop System Information ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Docker Version: $(docker --version)"
echo "Nginx Status: $(systemctl is-active nginx)"
echo "Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo "Disk Usage:"
df -h /
echo "Memory Usage:"
free -h
echo "====================================="
EOF

chmod +x /opt/online-shop/system-info.sh
chown ec2-user:ec2-user /opt/online-shop/system-info.sh

# ============================================================================
# Signal Completion
# ============================================================================

log "User data script execution completed successfully!"
log "System is ready for application deployment."

# Create completion marker
touch /opt/online-shop/.user-data-complete
chown ec2-user:ec2-user /opt/online-shop/.user-data-complete

# Send completion signal to CloudFormation (if needed)
# /opt/aws/bin/cfn-signal -e $? --stack STACK_NAME --resource AutoScalingGroup --region REGION

log "🎉 Online Shop infrastructure setup completed!"
