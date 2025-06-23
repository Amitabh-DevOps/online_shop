#!/bin/bash

# User data script for Online Shop EC2 instance
# This script sets up Docker, installs CloudWatch agent, and runs the application

set -e

# Variables from Terraform template
DOCKER_IMAGE="${docker_image}"
APP_PORT="${app_port}"
LOG_GROUP_NAME="${log_group_name}"
AWS_REGION="${aws_region}"
APP_VERSION="${app_version}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "Starting user data script execution"
log "Docker Image: $DOCKER_IMAGE"
log "App Port: $APP_PORT"
log "App Version: $APP_VERSION"

# Update system packages
log "Updating system packages"
yum update -y

# Install Docker
log "Installing Docker"
yum install -y docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -a -G docker ec2-user

# Install Docker Compose
log "Installing Docker Compose"
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install CloudWatch agent
log "Installing CloudWatch agent"
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
log "Configuring CloudWatch agent"
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "$LOG_GROUP_NAME",
                        "log_stream_name": "{instance_id}/user-data",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/docker.log",
                        "log_group_name": "$LOG_GROUP_NAME",
                        "log_stream_name": "{instance_id}/docker",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/application.log",
                        "log_group_name": "$LOG_GROUP_NAME",
                        "log_stream_name": "{instance_id}/application",
                        "timezone": "UTC"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "OnlineShop/EC2",
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
            "diskio": {
                "measurement": [
                    "io_time"
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

# Start CloudWatch agent
log "Starting CloudWatch agent"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create application directory
log "Creating application directory"
mkdir -p /opt/online-shop
cd /opt/online-shop

# Create docker-compose file for better container management
log "Creating Docker Compose configuration"
cat > docker-compose.yml << EOF
version: '3.8'

services:
  online-shop:
    image: $DOCKER_IMAGE
    container_name: online-shop-app
    ports:
      - "$APP_PORT:3000"
    environment:
      - NODE_ENV=production
      - APP_VERSION=$APP_VERSION
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

# Pull the Docker image
log "Pulling Docker image: $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE 2>&1 | tee -a /var/log/docker.log

# Start the application using Docker Compose
log "Starting application with Docker Compose"
/usr/local/bin/docker-compose up -d 2>&1 | tee -a /var/log/docker.log

# Wait for application to start
log "Waiting for application to start"
sleep 30

# Health check
log "Performing initial health check"
for i in {1..10}; do
    if curl -f -s http://localhost:$APP_PORT/ > /dev/null; then
        log "Application health check passed"
        break
    else
        log "Health check attempt $i failed, retrying in 10 seconds"
        sleep 10
    fi
    
    if [ $i -eq 10 ]; then
        log "Application health check failed after 10 attempts"
        # Log container status for debugging
        docker ps -a >> /var/log/docker.log
        docker logs online-shop-app >> /var/log/application.log 2>&1
    fi
done

# Create systemd service for auto-restart
log "Creating systemd service for application"
cat > /etc/systemd/system/online-shop.service << EOF
[Unit]
Description=Online Shop Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/online-shop
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable online-shop.service

# Create monitoring script
log "Creating monitoring script"
cat > /opt/online-shop/monitor.sh << 'EOF'
#!/bin/bash

# Simple monitoring script for the Online Shop application
LOG_FILE="/var/log/application.log"
APP_PORT="3000"

check_application() {
    if curl -f -s http://localhost:$APP_PORT/ > /dev/null; then
        echo "[$(date)] Application is healthy" >> $LOG_FILE
        return 0
    else
        echo "[$(date)] Application health check failed" >> $LOG_FILE
        return 1
    fi
}

restart_application() {
    echo "[$(date)] Restarting application" >> $LOG_FILE
    cd /opt/online-shop
    /usr/local/bin/docker-compose restart
    sleep 30
}

# Main monitoring logic
if ! check_application; then
    echo "[$(date)] Application is down, attempting restart" >> $LOG_FILE
    restart_application
    
    # Check again after restart
    if check_application; then
        echo "[$(date)] Application successfully restarted" >> $LOG_FILE
    else
        echo "[$(date)] Application restart failed" >> $LOG_FILE
    fi
fi
EOF

chmod +x /opt/online-shop/monitor.sh

# Add monitoring script to crontab (runs every 5 minutes)
log "Setting up monitoring cron job"
echo "*/5 * * * * /opt/online-shop/monitor.sh" | crontab -

# Install additional monitoring tools
log "Installing additional monitoring tools"
yum install -y htop iotop nethogs

# Create cleanup script
log "Creating cleanup script"
cat > /opt/online-shop/cleanup.sh << 'EOF'
#!/bin/bash

# Cleanup script for Docker resources
echo "[$(date)] Running cleanup tasks"

# Remove unused Docker images
docker image prune -f

# Remove unused Docker containers
docker container prune -f

# Remove unused Docker networks
docker network prune -f

# Remove unused Docker volumes
docker volume prune -f

echo "[$(date)] Cleanup completed"
EOF

chmod +x /opt/online-shop/cleanup.sh

# Schedule weekly cleanup
echo "0 2 * * 0 /opt/online-shop/cleanup.sh >> /var/log/cleanup.log 2>&1" | crontab -l | { cat; echo "0 2 * * 0 /opt/online-shop/cleanup.sh >> /var/log/cleanup.log 2>&1"; } | crontab -

# Final status check
log "Performing final status check"
docker ps -a | tee -a /var/log/docker.log
systemctl status docker | tee -a /var/log/docker.log

# Log completion
log "User data script execution completed successfully"
log "Application should be accessible at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):$APP_PORT"

# Send completion signal (CloudFormation not used, but keeping for compatibility)
# /opt/aws/bin/cfn-signal -e $? --stack StackName --resource AutoScalingGroup --region $AWS_REGION 2>/dev/null || true

exit 0
