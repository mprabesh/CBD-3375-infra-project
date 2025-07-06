# Azure Infrastructure Project - Student Guide

## Quick Start

### 1. Prerequisites Check
```bash
# Check Azure login
az account show

# Check Terraform
terraform --version
```

### 2. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure
terraform apply
```

### 3. Access Your VMs
```bash
# Download SSH key from Key Vault
az keyvault secret download --vault-name [VAULT-NAME] --name cbd-3375-ssh-key-private --file temp-key.pem
chmod 600 temp-key.pem

# SSH to web VM (get IP from terraform output)
ssh -i temp-key.pem sevastopol@[WEB-VM-PUBLIC-IP]

# Clean up key file
rm temp-key.pem
```

## What Gets Created

- **Resource Group**: CBD-3375-resources
- **Virtual Network**: 10.0.0.0/16 with public (10.0.1.0/24) and private (10.0.2.0/24) subnets
- **3 Virtual Machines**:
  - Web VM (public subnet, has public IP)
  - Backend VM (private subnet, Docker enabled)
  - Database VM (private subnet)
- **Security**: Network Security Groups, NAT Gateway, Azure Key Vault
- **SSH Keys**: Automatically generated and stored in Key Vault

## Useful Commands

```bash
# Check infrastructure status
terraform show

# Get outputs (VM IPs, etc.)
terraform output

# Destroy everything when done
terraform destroy
```

## Troubleshooting

**Problem**: Permission errors during deployment
**Solution**: Make sure you're logged in with `az login`

**Problem**: Can't SSH to VMs
**Solution**: Download the SSH key from Key Vault first

**Problem**: VMs not accessible
**Solution**: Check Network Security Group rules are applied

## Project Structure

```
├── main.tf                    # Main configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars           # Your values
├── modules/                   # Modular components
│   ├── resource_group/
│   ├── networking/
│   ├── virtual_machine/
│   └── key_vault/
└── scripts/                   # Docker installation scripts
```

## Security Features

- SSH keys stored in Azure Key Vault
- Network Security Groups with restrictive rules
- Private subnet with NAT Gateway for internet access
- Managed identities for VMs to access Key Vault

That's it! Simple manual deployment for your student account. 🚀
