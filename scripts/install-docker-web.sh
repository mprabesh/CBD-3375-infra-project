#!/bin/bash

# Docker installation script for Web VM
# This script will be executed during VM bootstrap

echo "Starting Docker installation on Web VM..." > /var/log/docker-install.log

# Update package index
apt-get update -y >> /var/log/docker-install.log 2>&1

# Install required packages
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release >> /var/log/docker-install.log 2>&1

# Add Docker's official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
apt-get update -y >> /var/log/docker-install.log 2>&1

# Install Docker Engine
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> /var/log/docker-install.log 2>&1

# Start and enable Docker service
systemctl start docker >> /var/log/docker-install.log 2>&1
systemctl enable docker >> /var/log/docker-install.log 2>&1

# Add user to docker group
usermod -aG docker ${admin_username} >> /var/log/docker-install.log 2>&1

# Verify Docker installation
docker --version >> /var/log/docker-install.log 2>&1
docker compose version >> /var/log/docker-install.log 2>&1

echo "Docker installation completed successfully on Web VM at $(date)" >> /var/log/docker-install.log
