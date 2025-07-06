# GitHub CI/CD Setup Guide

This guide explains how to set up GitHub Actions for automated Terraform deployment to Azure.

## Overview

The GitHub Actions workflow is configured to:
- Authenticate with Azure using a service principal
- Run Terraform validate, plan, and apply operations
- Only deploy changes when pushing to the main branch
- Upload Terraform outputs as artifacts

## Prerequisites

1. Azure subscription with appropriate permissions
2. GitHub repository with the Terraform code
3. Azure CLI installed locally (for setup only)

## Step 1: Create Azure Service Principal

Run these commands locally to create a service principal for GitHub Actions:

```bash
# Set your subscription ID
SUBSCRIPTION_ID="your-subscription-id"

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-terraform" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth
```

This will output JSON similar to:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

## Step 2: Configure GitHub Secrets

In your GitHub repository, go to Settings > Secrets and variables > Actions, and create these secrets:

### Required Secrets:

1. **AZURE_CREDENTIALS** - The entire JSON output from the service principal creation
2. **AZURE_CLIENT_ID** - The clientId from the JSON
3. **AZURE_CLIENT_SECRET** - The clientSecret from the JSON  
4. **AZURE_SUBSCRIPTION_ID** - The subscriptionId from the JSON
5. **AZURE_TENANT_ID** - The tenantId from the JSON

### How to Add Secrets:

1. Go to your GitHub repository
2. Click Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Add each secret with the name and value

## Step 3: Verify Service Principal Permissions

Ensure the service principal has the necessary permissions:

```bash
# Check role assignments
az role assignment list --assignee "your-client-id" --output table

# If needed, add additional permissions for Key Vault
az role assignment create \
  --assignee "your-client-id" \
  --role "Key Vault Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

## Step 4: Test the Workflow

1. Push changes to a feature branch to trigger validation
2. Create a pull request to run plan
3. Merge to main to trigger deployment

## Workflow Behavior

- **Push to any branch**: Runs terraform validate and plan
- **Pull request**: Runs terraform validate and plan
- **Push to main**: Runs validate, plan, and apply
- **Manual trigger**: Can be triggered via workflow_dispatch

## Security Best Practices

1. **Service Principal Scope**: The service principal is scoped to your subscription with Contributor role
2. **Secrets Protection**: GitHub secrets are encrypted and only accessible during workflow runs
3. **Branch Protection**: Only main branch deployments are applied automatically
4. **Terraform State**: Ensure your Terraform state is stored securely (Azure Storage Account with locks)

## Troubleshooting

### Common Issues:

1. **Authentication Error**: Verify all GitHub secrets are correctly set
2. **Permission Denied**: Check service principal role assignments
3. **Terraform State Lock**: Ensure no manual Terraform operations are running

### Debug Commands:

```bash
# Test service principal authentication locally
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID

# Test Terraform authentication
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
terraform plan
```

## Additional Configuration

### Terraform Backend Configuration

For production use, configure remote state storage:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "terraformstatesa"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

### Environment-Specific Deployments

For multiple environments, consider:
- Separate GitHub secrets per environment
- Environment-specific terraform.tfvars files
- Branch-based deployment strategies

## Next Steps

1. Set up the GitHub secrets as described above
2. Test the workflow with a small change
3. Monitor the Actions tab for deployment results
4. Set up branch protection rules for additional security
