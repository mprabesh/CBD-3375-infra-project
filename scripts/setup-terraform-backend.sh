#!/bin/bash

# Terraform Remote State Backend Setup Script
# This script creates Azure Storage Account for Terraform state management

set -e

echo "Terraform Remote State Backend Setup"
echo "===================================="

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo "Please log in to Azure first:"
    echo "az login"
    exit 1
fi

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo "Current subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
echo ""

# Set variables
RESOURCE_GROUP_NAME="terraform-state-rg"
TIMESTAMP=$(date +%s)
STORAGE_ACCOUNT_NAME="tfstate${TIMESTAMP}"
CONTAINER_NAME="tfstate"
LOCATION="East US"

echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo "  Location: $LOCATION"
echo ""

read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

echo "Creating resource group: $RESOURCE_GROUP_NAME"
az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION" --output table

echo ""
echo "Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --output table

echo ""
echo "Creating container: $CONTAINER_NAME"
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --output table

echo ""
echo "Enabling versioning and soft delete..."
az storage account blob-service-properties update \
  --account-name $STORAGE_ACCOUNT_NAME \
  --enable-versioning \
  --enable-delete-retention \
  --delete-retention-days 7

echo ""
echo "============================================"
echo "BACKEND CONFIGURATION FOR MAIN.TF:"
echo "============================================"
cat << EOF

Add this to the top of your main.tf file:

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  backend "azurerm" {
    resource_group_name  = "$RESOURCE_GROUP_NAME"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "terraform.tfstate"
  }
}
EOF

echo ""
echo "============================================"
echo "SERVICE PRINCIPAL PERMISSIONS:"
echo "============================================"
echo ""
echo "If you're using GitHub Actions, grant your service principal access:"
echo ""
echo "az role assignment create \\"
echo "  --assignee \"your-service-principal-client-id\" \\"
echo "  --role \"Storage Blob Data Contributor\" \\"
echo "  --scope \"/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME\""
echo ""

echo "============================================"
echo "NEXT STEPS:"
echo "============================================"
echo "1. Add the backend configuration to your main.tf"
echo "2. Run: terraform init -migrate-state"
echo "3. Verify: terraform plan"
echo "4. Commit and push your changes"
echo "5. Grant service principal permissions (if using CI/CD)"
echo ""

# Offer to grant permissions automatically if service principal client ID is provided
echo "Optional: Grant permissions to service principal now"
read -p "Enter service principal client ID (or press Enter to skip): " SP_CLIENT_ID

if [[ ! -z "$SP_CLIENT_ID" ]]; then
    echo "Granting Storage Blob Data Contributor role to $SP_CLIENT_ID..."
    az role assignment create \
      --assignee "$SP_CLIENT_ID" \
      --role "Storage Blob Data Contributor" \
      --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
    echo "Permissions granted!"
fi

echo ""
echo "Setup complete! 🚀"
echo ""
echo "Storage account details:"
echo "  Name: $STORAGE_ACCOUNT_NAME"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Container: $CONTAINER_NAME"
