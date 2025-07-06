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
```bash
# Get VM details
terraform output

# Download SSH key and connect
az keyvault secret download --vault-name [VAULT-NAME] --name cbd-3375-ssh-key-private --file temp-key.pem
chmod 600 temp-key.pem
ssh -i temp-key.pem sevastopol@[WEB-VM-IP]
rm temp-key.pem
```

## What's Included

- **Infrastructure**: VNet, subnets, NSGs, NAT Gateway
- **VMs**: Web (public), Backend (private), Database (private)
- **Security**: Key Vault, SSH keys, managed identities
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
