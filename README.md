# Azure Infrastructure Project

Simple Terraform configuration for Azure VMs with networking, security, and Key Vault integration.

## Quick Start

### Prerequisites
- Azure CLI installed and logged in (`az login`)
- Terraform installed

### Deploy
```bash
# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### Access VMs

#### Step 1: Get VM Information
```bash
# Get VM details and Key Vault name
terraform output
```

#### Step 2: Download SSH Key from Azure Key Vault
```bash
# Download SSH private key (replace VAULT-NAME with your Key Vault name)
az keyvault secret download \
  --vault-name [VAULT-NAME] \
  --name cbd-3375-ssh-key-private \
  --file temp-key.pem

# Set correct permissions
chmod 600 temp-key.pem
```

#### Step 3: Connect to VMs

**Connect to Web VM (Public - Direct Access):**
```bash
# Replace [WEB-VM-IP] with your web VM's public IP
ssh -i temp-key.pem sevastopol@[WEB-VM-IP]
```

**Connect to Backend VM (Private - via Jump Host):**
```bash
# Copy SSH key to Web VM first
scp -i temp-key.pem temp-key.pem sevastopol@[WEB-VM-IP]:~/backend-key.pem

# SSH to Web VM, then to Backend VM
ssh -i temp-key.pem sevastopol@[WEB-VM-IP]
# On Web VM:
chmod 600 ~/backend-key.pem
ssh -i ~/backend-key.pem sevastopol@[BACKEND-VM-PRIVATE-IP]
```

**Connect to Database VM (Private - via Jump Host):**
```bash
# From Web VM (after connecting as above)
ssh -i ~/backend-key.pem sevastopol@[DATABASE-VM-PRIVATE-IP]
```

#### Step 4: Clean Up SSH Key
```bash
# Remove local SSH key when done
rm temp-key.pem
```

#### Example with Real IPs:
```bash
# 1. Download key
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file temp-key.pem
chmod 600 temp-key.pem

# 2. Connect to Web VM
ssh -i temp-key.pem sevastopol@20.1.2.3

# 3. From Web VM, connect to Backend/Database
ssh -i ~/backend-key.pem sevastopol@10.0.2.4  # Backend VM
ssh -i ~/backend-key.pem sevastopol@10.0.2.5  # Database VM
```

## Deploy Docker Applications

After infrastructure is deployed, use the Docker deployment script:

### Option 1: Auto-extract from Terraform
```bash
# Deploy with default images (nginx, node:18-alpine, postgres:15)
./scripts/deploy-docker.sh --from-terraform
```

### Option 2: Manual IP specification
```bash
# Deploy with specific IPs and custom images
./scripts/deploy-docker.sh \
  -w 20.1.2.3 \
  -b 10.0.2.4 \
  -d 10.0.2.5 \
  -k CBD-3375-kv-unique123 \
  --web-image nginx:alpine \
  --backend-image node:16-slim \
  --database-image postgres:14
```

### Verify Deployment
```bash
# Verify all containers are running
./scripts/verify-deployment.sh --from-terraform

# Or with manual IPs
./scripts/verify-deployment.sh -w 20.1.2.3 -k CBD-3375-kv-unique123
```

## Troubleshooting

### SSH Connection Issues

**Problem**: Cannot connect to Web VM
```bash
# Solution: Check VM is running and get correct IP
terraform output
az vm list --resource-group CBD-3375-resources --output table
```

**Problem**: "Permission denied (publickey)"
```bash
# Solution: Ensure SSH key has correct permissions
chmod 600 temp-key.pem

# Verify key is correct
ssh-keygen -l -f temp-key.pem
```

**Problem**: Cannot reach Backend/Database VMs
```bash
# Solution: These VMs are in private subnets, use Web VM as jump host
# 1. Connect to Web VM first
ssh -i temp-key.pem sevastopol@[WEB-VM-IP]

# 2. Copy SSH key to Web VM
scp -i temp-key.pem temp-key.pem sevastopol@[WEB-VM-IP]:~/backend-key.pem

# 3. From Web VM, connect to private VMs
ssh -i ~/backend-key.pem sevastopol@[BACKEND-VM-IP]
```

### Docker Deployment Issues

**Problem**: Docker containers not starting
```bash
# Solution: Check Docker status on VMs
ssh -i temp-key.pem sevastopol@[WEB-VM-IP] "sudo docker ps -a"
ssh -i temp-key.pem sevastopol@[WEB-VM-IP] "sudo docker logs [CONTAINER-NAME]"
```

**Problem**: Cannot pull Docker images
```bash
# Solution: Check internet connectivity and Docker daemon
ssh -i temp-key.pem sevastopol@[WEB-VM-IP] "sudo systemctl status docker"
ssh -i temp-key.pem sevastopol@[WEB-VM-IP] "ping google.com"
```

### Key Vault Access Issues

**Problem**: Cannot download SSH key from Key Vault
```bash
# Solution: Check Azure login and Key Vault permissions
az login
az account show
az keyvault list --output table
```

## What's Included

- **Infrastructure**: VNet, subnets, NSGs, NAT Gateway
- **VMs**: Web (public), Backend (private), Database (private)
- **Security**: Key Vault, SSH keys, managed identities
- **Automation**: Docker installation scripts

## Quick Reference

### Common Commands
```bash
# Deploy infrastructure
terraform init && terraform plan && terraform apply

# Get connection details
terraform output

# Download SSH key
az keyvault secret download --vault-name [VAULT-NAME] --name cbd-3375-ssh-key-private --file temp-key.pem && chmod 600 temp-key.pem

# Deploy Docker containers
./scripts/deploy-docker.sh --from-terraform

# Verify deployment
./scripts/verify-deployment.sh --from-terraform

# Connect to Web VM
ssh -i temp-key.pem sevastopol@[WEB-VM-IP]

# Check Docker containers
sudo docker ps

# View container logs
sudo docker logs [CONTAINER-NAME]

# Clean up
terraform destroy
rm temp-key.pem
```

### Network Architecture
```
Internet → Public IP → Web VM (10.0.1.x) → Backend VM (10.0.2.x) → Database VM (10.0.2.x)
                         ↓                      ↓                     ↓
                    React App:80          Node.js API:3003      PostgreSQL:5432
```

### Access URLs
- **Web Frontend**: `http://[WEB-VM-PUBLIC-IP]`
- **Backend API**: `http://[BACKEND-VM-PRIVATE-IP]:3003` (internal only)
- **Database**: `[DATABASE-VM-PRIVATE-IP]:5432` (internal only)
- **Automation**: Docker installation scripts

## Configuration

Copy and customize your variables:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferences
```

## Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete deployment instructions

## Cleanup

```bash
terraform destroy
```

Simple, secure, and ready to deploy! 🚀
