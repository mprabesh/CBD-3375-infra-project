#!/bin/bash

# Node.js installation script for Backend VM (Git-based deployment)
# This script will be executed during VM bootstrap

echo "Starting Node.js installation on Backend VM..." > /var/log/nodejs-install.log

# Update package index
apt-get update -y >> /var/log/nodejs-install.log 2>&1

# Install required packages
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    build-essential >> /var/log/nodejs-install.log 2>&1

# Add Node.js official GPG key and repository
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - >> /var/log/nodejs-install.log 2>&1

# Install Node.js
apt-get install -y nodejs >> /var/log/nodejs-install.log 2>&1

# Install PM2 globally for process management
npm install -g pm2 >> /var/log/nodejs-install.log 2>&1

# Add user to any necessary groups (if admin_username is provided)
if [ -n "${admin_username}" ]; then
    usermod -aG sudo ${admin_username} >> /var/log/nodejs-install.log 2>&1 || true
fi

# Verify Node.js installation
node --version >> /var/log/nodejs-install.log 2>&1
npm --version >> /var/log/nodejs-install.log 2>&1
pm2 --version >> /var/log/nodejs-install.log 2>&1

echo "Node.js installation completed successfully on Backend VM at $(date)" >> /var/log/nodejs-install.log
