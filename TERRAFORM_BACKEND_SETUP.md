# Terraform Remote State Setup Guide

This guide explains how to set up remote state storage for Terraform, which is essential for CI/CD pipelines.

## Why Remote State?

Local Terraform state files (terraform.tfstate) cannot be used in CI/CD pipelines because:
- They're not accessible to GitHub Actions runners
- Multiple team members need shared access
- State locking prevents concurrent operations
- State files contain sensitive information

## Option 1: Azure Storage Backend (Recommended)

### Step 1: Create Storage Account for Terraform State

```bash
# Set variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstate$(date +%s)"  # Must be globally unique
CONTAINER_NAME="tfstate"
LOCATION="East US"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

### Step 2: Update main.tf

Add this backend configuration to your `main.tf`:

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "your-storage-account-name"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

### Step 3: Initialize Backend

```bash
# Migrate existing state to remote backend
terraform init -migrate-state

# Confirm migration
terraform plan
```

## Option 2: Terraform Cloud (Alternative)

### Step 1: Create Terraform Cloud Account

1. Go to https://app.terraform.io/
2. Create account and organization
3. Create workspace

### Step 2: Configure Backend

```hcl
terraform {
  cloud {
    organization = "your-org-name"
    
    workspaces {
      name = "azure-infrastructure"
    }
  }
}
```

### Step 3: Authenticate

```bash
# Login to Terraform Cloud
terraform login

# Initialize
terraform init
```

## Recommended Setup Script

Here's a complete script to set up Azure Storage backend:

```bash
#!/bin/bash
# setup-terraform-backend.sh

set -e

echo "Setting up Terraform remote state storage..."

# Variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstate$(date +%s)"
CONTAINER_NAME="tfstate"
LOCATION="East US"

# Create resources
echo "Creating resource group: $RESOURCE_GROUP_NAME"
az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"

echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob

echo "Creating container: $CONTAINER_NAME"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME

echo ""
echo "Backend configuration for main.tf:"
echo "=================================="
cat << EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "terraform.tfstate"
  }
}
EOF

echo ""
echo "Next steps:"
echo "1. Add the backend configuration to your main.tf"
echo "2. Run: terraform init -migrate-state"
echo "3. Commit and push your changes"
```

## Security Considerations

### Storage Account Access

The service principal needs access to the storage account:

```bash
# Grant Storage Blob Data Contributor to service principal
az role assignment create \
  --assignee "your-service-principal-client-id" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/your-subscription-id/resourceGroups/terraform-state-rg/providers/Microsoft.Storage/storageAccounts/your-storage-account"
```

### State File Encryption

- Azure Storage encrypts data at rest by default
- Consider using customer-managed keys for additional security
- Enable soft delete and versioning on the storage account

## Testing the Setup

1. **Local Testing**:
   ```bash
   terraform init
   terraform plan
   ```

2. **CI/CD Testing**:
   - Push a small change
   - Monitor GitHub Actions workflow
   - Verify state is updated in Azure Storage

## Troubleshooting

### Common Issues:

1. **Storage account name conflicts**: Names must be globally unique
2. **Permission errors**: Ensure service principal has Storage Blob Data Contributor role
3. **State lock errors**: Check for stuck locks in storage account

### Debug Commands:

```bash
# List state files in storage
az storage blob list \
  --container-name tfstate \
  --account-name your-storage-account

# Check storage account permissions
az role assignment list \
  --scope "/subscriptions/your-subscription-id/resourceGroups/terraform-state-rg"
```

## Migration from Local State

If you have existing local state:

1. **Backup current state**:
   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

2. **Add backend configuration** to main.tf

3. **Initialize and migrate**:
   ```bash
   terraform init -migrate-state
   ```

4. **Verify migration**:
   ```bash
   terraform plan  # Should show no changes
   ```

5. **Clean up local files** (optional):
   ```bash
   rm terraform.tfstate*
   ```

The local state files are already in .gitignore, so they won't be committed.
