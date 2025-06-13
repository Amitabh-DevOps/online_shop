#!/bin/bash

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    wget

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ubuntu user to docker group
usermod -aG docker ubuntu

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Create application directory
mkdir -p /opt/online-shop
chown ubuntu:ubuntu /opt/online-shop

# Create systemd service for the application
cat > /etc/systemd/system/online-shop.service << 'EOF'
[Unit]
Description=Online Shop Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker run -d --name online-shop -p 80:3000 --restart unless-stopped amitabhdevops/online-shop:latest
ExecStop=/usr/bin/docker stop online-shop
ExecStopPost=/usr/bin/docker rm online-shop
User=ubuntu
Group=docker

[Install]
WantedBy=multi-user.target
EOF

# Enable the service (but don't start it yet - will be started by deployment)
systemctl daemon-reload
systemctl enable online-shop

# Configure log rotation for Docker
cat > /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Set up basic firewall (ufw)
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 3000

# Create a simple health check script
cat > /home/ubuntu/health-check.sh << 'EOF'
#!/bin/bash
if curl -f -s http://localhost > /dev/null; then
    echo "Application is healthy"
    exit 0
else
    echo "Application is not responding"
    exit 1
fi
EOF

chmod +x /home/ubuntu/health-check.sh
chown ubuntu:ubuntu /home/ubuntu/health-check.sh

# Log the completion
echo "$(date): User data script completed successfully" >> /var/log/user-data.log
