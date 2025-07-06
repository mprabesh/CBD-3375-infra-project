#!/bin/bash

# GitHub Actions Service Principal Setup Script
# This script creates a service principal for GitHub Actions and displays the required secrets

set -e

echo "GitHub Actions Service Principal Setup"
echo "======================================"

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

read -p "Do you want to continue with this subscription? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled. Use 'az account set --subscription <subscription-id>' to change subscription."
    exit 0
fi

echo "Creating service principal..."

# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "github-actions-terraform-$(date +%s)" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth)

echo ""
echo "Service principal created successfully!"
echo ""
echo "============================================"
echo "GITHUB SECRETS TO CREATE:"
echo "============================================"
echo ""

# Extract values from JSON
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.clientSecret')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')

echo "1. AZURE_CREDENTIALS:"
echo "$SP_OUTPUT"
echo ""
echo "2. AZURE_CLIENT_ID:"
echo "$CLIENT_ID"
echo ""
echo "3. AZURE_CLIENT_SECRET:"
echo "$CLIENT_SECRET"
echo ""
echo "4. AZURE_SUBSCRIPTION_ID:"
echo "$SUBSCRIPTION_ID"
echo ""
echo "5. AZURE_TENANT_ID:"
echo "$TENANT_ID"
echo ""
echo "============================================"
echo "NEXT STEPS:"
echo "============================================"
echo "1. Go to your GitHub repository"
echo "2. Navigate to Settings > Secrets and variables > Actions"
echo "3. Create the 5 secrets listed above"
echo "4. Test the workflow by pushing a commit"
echo ""
echo "For detailed instructions, see GITHUB_CICD_SETUP.md"
echo ""

# Optional: Add Key Vault permissions
read -p "Do you want to add Key Vault Contributor permissions? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Adding Key Vault Contributor role..."
    az role assignment create \
      --assignee "$CLIENT_ID" \
      --role "Key Vault Contributor" \
      --scope "/subscriptions/$SUBSCRIPTION_ID"
    echo "Key Vault Contributor role added."
fi

echo ""
echo "Setup complete! 🚀"
