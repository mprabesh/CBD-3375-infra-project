# Accessing Azure Key Vault from VMs - Complete Guide

## 🔑 Overview

This guide explains how to access Azure Key Vault from your VMs using different authentication methods. I've already configured managed identity for all your VMs and granted them access to the Key Vault.

## 🛠️ Current Configuration Status

### ✅ What's Already Set Up:

1. **Managed Identity Enabled** on all VMs:
   - Web VM: `fa3e9dc0-ebaf-460d-8244-d51c7ee68f41`
   - Backend VM: `d3b22848-530f-431c-8fc2-b144662565fc`
   - Database VM: `f8495818-1acc-4245-b947-0af60609beee`

2. **Key Vault Access Policies** configured for all VMs:
   - Secret permissions: `get`, `list`
   - All VMs can read secrets from Key Vault

3. **Azure CLI Installed** on Web VM for testing

## 🔐 Method 1: Managed Identity (Recommended - Production)

### From Web VM:
```bash
# SSH to web VM
ssh -i temp-key.pem sevastopol@4.157.252.199

# Login using managed identity
az login --identity --allow-no-subscriptions

# List all secrets in Key Vault
az keyvault secret list --vault-name CBD-3375-kv-unique123

# Get SSH private key
az keyvault secret show --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --query value -o tsv

# Get SSH public key
az keyvault secret show --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-public --query value -o tsv

# Download private key to file
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file vm-ssh-key.pem
chmod 600 vm-ssh-key.pem
```

### From Backend/Database VMs:
```bash
# First, install Azure CLI on the VM
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login using managed identity
az login --identity --allow-no-subscriptions

# Access Key Vault secrets
az keyvault secret list --vault-name CBD-3375-kv-unique123
```

## 🐍 Method 2: Using Azure SDK for Python

### Install Azure SDK:
```bash
# On any VM
sudo apt update
sudo apt install python3-pip -y
pip3 install azure-keyvault-secrets azure-identity
```

### Python Script Example:
```python
#!/usr/bin/env python3
from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential

# Use managed identity to authenticate
credential = ManagedIdentityCredential()

# Create Key Vault client
client = SecretClient(
    vault_url="https://cbd-3375-kv-unique123.vault.azure.net/", 
    credential=credential
)

# List all secrets
print("Secrets in Key Vault:")
for secret in client.list_properties_of_secrets():
    print(f"- {secret.name}")

# Get SSH private key
ssh_private = client.get_secret("cbd-3375-ssh-key-private")
print(f"SSH Private Key: {ssh_private.value[:50]}...")

# Get SSH public key
ssh_public = client.get_secret("cbd-3375-ssh-key-public")
print(f"SSH Public Key: {ssh_public.value}")
```

### Run the script:
```bash
# Save as keyvault_access.py and run
python3 keyvault_access.py
```

## 🌐 Method 3: REST API Calls

### Get Access Token:
```bash
# Get managed identity token
TOKEN=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H Metadata:true | jq -r .access_token)
```

### Access Key Vault via REST:
```bash
# List secrets
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://cbd-3375-kv-unique123.vault.azure.net/secrets?api-version=7.3" | jq

# Get specific secret
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://cbd-3375-kv-unique123.vault.azure.net/secrets/cbd-3375-ssh-key-private?api-version=7.3" | jq -r .value
```

## 🐳 Method 4: Using Docker Containers

### Dockerfile with Azure CLI:
```dockerfile
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y curl jq
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
COPY keyvault-script.sh /app/
WORKDIR /app
CMD ["./keyvault-script.sh"]
```

### Script for container:
```bash
#!/bin/bash
# keyvault-script.sh
az login --identity --allow-no-subscriptions
az keyvault secret list --vault-name CBD-3375-kv-unique123
```

## 📋 Practical Use Cases

### 1. Database Connection Strings
Store database passwords in Key Vault and retrieve them:

```bash
# Store database password in Key Vault
az keyvault secret set --vault-name CBD-3375-kv-unique123 --name "db-password" --value "SecurePassword123!"

# Retrieve in application
DB_PASSWORD=$(az keyvault secret show --vault-name CBD-3375-kv-unique123 --name db-password --query value -o tsv)
```

### 2. API Keys and Certificates
```bash
# Store API key
az keyvault secret set --vault-name CBD-3375-kv-unique123 --name "external-api-key" --value "abc123xyz"

# Retrieve for application
API_KEY=$(az keyvault secret show --vault-name CBD-3375-kv-unique123 --name external-api-key --query value -o tsv)
export API_KEY
```

### 3. SSH Key Management for CI/CD
```bash
# Download SSH keys for automated deployments
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file deployment-key.pem
chmod 600 deployment-key.pem

# Use for Git or other SSH connections
ssh-add deployment-key.pem
git clone git@github.com:user/repo.git
```

## 🔧 Automated Setup Script

### Complete setup script for any VM:
```bash
#!/bin/bash
# setup-keyvault-access.sh

echo "Setting up Azure Key Vault access..."

# Install Azure CLI if not present
if ! command -v az &> /dev/null; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Login using managed identity
echo "Authenticating with managed identity..."
az login --identity --allow-no-subscriptions

# Test Key Vault access
echo "Testing Key Vault access..."
az keyvault secret list --vault-name CBD-3375-kv-unique123 --query '[].name' -o tsv

# Create helper functions
cat > ~/.bashrc_keyvault << 'EOF'
# Key Vault helper functions
function kv-get() {
    az keyvault secret show --vault-name CBD-3375-kv-unique123 --name "$1" --query value -o tsv
}

function kv-list() {
    az keyvault secret list --vault-name CBD-3375-kv-unique123 --query '[].name' -o tsv
}

function kv-download() {
    az keyvault secret download --vault-name CBD-3375-kv-unique123 --name "$1" --file "$2"
}
EOF

echo "source ~/.bashrc_keyvault" >> ~/.bashrc

echo "Setup complete! Key Vault access is now available."
echo "Usage examples:"
echo "  kv-list                              # List all secrets"
echo "  kv-get ssh-private-key              # Get secret value"
echo "  kv-download ssh-private-key key.pem # Download to file"
```

## 🚨 Security Best Practices

### 1. Principle of Least Privilege
```bash
# VMs only have 'get' and 'list' permissions
# No 'set', 'delete', or administrative permissions
```

### 2. Audit and Monitoring
```bash
# Enable Key Vault logging (already configured)
# Monitor access in Azure portal under Key Vault > Logs
```

### 3. Secure Secret Handling
```bash
# Always use environment variables, never hardcode
SECRET=$(kv-get "my-secret")
export MY_APP_SECRET="$SECRET"

# Clear variables after use
unset SECRET MY_APP_SECRET
```

## 🔍 Troubleshooting

### Common Issues:

1. **"No access was configured for the VM"**
   ```bash
   # Use --allow-no-subscriptions flag
   az login --identity --allow-no-subscriptions
   ```

2. **"Access denied to Key Vault"**
   ```bash
   # Check if managed identity has proper permissions
   az keyvault show --name CBD-3375-kv-unique123 --query properties.accessPolicies
   ```

3. **"Managed identity not found"**
   ```bash
   # Verify managed identity is enabled
   curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/' -H Metadata:true
   ```

## 📊 Testing Commands

### Verify everything is working:
```bash
# 1. Test managed identity
az login --identity --allow-no-subscriptions

# 2. List Key Vault secrets
az keyvault secret list --vault-name CBD-3375-kv-unique123

# 3. Get SSH keys
az keyvault secret show --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-public --query value -o tsv

# 4. Download and test SSH key
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file test-key.pem
chmod 600 test-key.pem
ssh-keygen -y -f test-key.pem  # Should display public key
```

## 🎯 Next Steps

1. **Set up automated scripts** on each VM for your applications
2. **Store additional secrets** (database passwords, API keys, etc.)
3. **Implement secret rotation** using Azure automation
4. **Monitor Key Vault access** through Azure logs

Your VMs now have secure, auditable access to Azure Key Vault using managed identities! 🔐✨
