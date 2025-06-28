# Azure VM Terraform Configuration

This Terraform configuration creates an Azure virtual machine with associated networking resources using a modular approach.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- Azure CLI installed (optional, for Azure CLI authentication)
- Azure subscription and appropriate permissions

## Authentication Options

### Option 1: Service Principal Authentication (Recommended for Automation)

1. Create an Azure Service Principal:
   ```bash
   az ad sp create-for-rbac --name "terraform-sp" --role Contributor --scopes /subscriptions/{subscription-id}
   ```

2. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Update `terraform.tfvars` with your Service Principal details:
   ```hcl
   client_id       = "your-service-principal-client-id"
   client_secret   = "your-service-principal-client-secret"
   tenant_id       = "your-azure-tenant-id"
   subscription_id = "your-azure-subscription-id"
   ```

### Option 2: Azure CLI Authentication

1. Comment out the Service Principal variables in `main.tf`
2. Uncomment the `use_cli = true` line in the provider block
3. Login to Azure CLI:
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

### Option 3: Managed Identity (For Azure VMs)

1. Comment out the Service Principal variables in `main.tf`
2. Uncomment the `use_msi = true` line in the provider block
3. Ensure your Azure VM has a managed identity with appropriate permissions

## Environment Variables (Alternative to terraform.tfvars)

You can also set authentication using environment variables:

```bash
export ARM_CLIENT_ID="your-service-principal-client-id"
export ARM_CLIENT_SECRET="your-service-principal-client-secret"
export ARM_TENANT_ID="your-azure-tenant-id"
export ARM_SUBSCRIPTION_ID="your-azure-subscription-id"
```

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the execution plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. To destroy the infrastructure:
   ```bash
   terraform destroy
   ```

## Module Structure

```
├── main.tf                    # Root configuration
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── terraform.tfvars.example   # Example variables file
└── modules/
    ├── resource_group/        # Resource group module
    ├── networking/            # VNet, subnet, NIC module
    └── virtual_machine/       # Virtual machine module
```

## Outputs

After successful deployment, you'll get:
- Resource group name and location
- Virtual network and subnet details
- Network interface ID
- Virtual machine name, admin username, and private IP

## Security Notes

- Never commit `terraform.tfvars` or any files containing secrets to version control
- Use Azure Key Vault for production secrets
- Consider using Managed Identity for Azure-hosted deployments
- The `.gitignore` file is configured to exclude sensitive files
