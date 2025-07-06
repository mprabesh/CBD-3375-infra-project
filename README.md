# Azure VM Terraform Configuration

This Terraform configuration creates an Azure virtual machine with associated networking resources using a modular approach.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- Azure CLI installed (optional, for Azure CLI authentication)
- Azure subscription and appropriate permissions

## Quick Start

### Local Development

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Update `terraform.tfvars` with your values

3. Deploy the infrastructure:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### CI/CD Setup

For automated deployments with GitHub Actions:

1. **Set up service principal**:
   ```bash
   ./scripts/setup-github-sp.sh
   ```

2. **Set up remote state storage** (recommended):
   ```bash
   ./scripts/setup-terraform-backend.sh
   ```

3. **Configure GitHub secrets** with the output from step 1

4. **Push to main branch** to trigger deployment

See [GITHUB_CICD_SETUP.md](GITHUB_CICD_SETUP.md) for detailed instructions.

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

## CI/CD Pipeline

This project includes a GitHub Actions workflow for automated deployment:

### Features
- **Automated validation** on pull requests
- **Automated deployment** on push to main branch
- **Secure authentication** using service principal
- **Terraform state management** with Azure Storage backend
- **Output artifacts** for downstream workflows

### Setup Instructions

1. **Service Principal**: Run `./scripts/setup-github-sp.sh` to create and configure
2. **Backend Storage**: Run `./scripts/setup-terraform-backend.sh` for remote state
3. **GitHub Secrets**: Configure the 5 required secrets in your repository
4. **Test**: Push a commit to trigger the workflow

See [GITHUB_CICD_SETUP.md](GITHUB_CICD_SETUP.md) for detailed setup instructions.

### Workflow Triggers
- **Push to any branch**: Validation and planning
- **Pull request**: Validation and planning  
- **Push to main**: Full deployment
- **Manual dispatch**: Can be triggered manually

## Additional Documentation

- [SSH Key Management Guide](SSH_KEY_GUIDE.md) - Comprehensive SSH key setup and usage
- [Secure SSH Access Guide](SECURE_SSH_GUIDE.md) - Security best practices for VM access
- [GitHub CI/CD Setup](GITHUB_CICD_SETUP.md) - Complete CI/CD configuration guide
- [Terraform Backend Setup](TERRAFORM_BACKEND_SETUP.md) - Remote state configuration
- [Security Enhancements Summary](SECURITY_ENHANCEMENT_SUMMARY.txt) - Overview of security features

## Project Structure

```
├── main.tf                           # Root configuration
├── variables.tf                      # Root variables  
├── outputs.tf                        # Root outputs
├── terraform.tfvars.example          # Example variables file
├── .github/workflows/deploy.yml       # CI/CD pipeline
├── scripts/
│   ├── setup-github-sp.sh            # Service principal setup
│   ├── setup-terraform-backend.sh    # Backend storage setup
│   ├── install-docker-web.sh         # Web server Docker setup
│   └── install-docker-backend.sh     # Backend server Docker setup
└── modules/
    ├── resource_group/               # Resource group module
    ├── networking/                   # VNet, subnet, NSG module
    ├── virtual_machine/              # Virtual machine module
    └── key_vault/                    # Key Vault module
```
