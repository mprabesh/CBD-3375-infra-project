# SSH Key Management for CBD-3375 Infrastructure

## Overview
This infrastructure automatically generates RSA SSH key pairs and stores them securely in Azure Key Vault. The SSH keys are used for secure authentication to all virtual machines in the environment.

## What Gets Created

### 1. Key Vault Resources
- **Azure Key Vault**: `CBD-3375-kv-unique123`
- **SSH Private Key Secret**: `cbd-3375-ssh-key-private`
- **SSH Public Key Secret**: `cbd-3375-ssh-key-public`

### 2. Local SSH Key Files
- **Private Key**: `ssh-keys/cbd-3375-ssh-key.pem` (600 permissions)
- **Public Key**: `ssh-keys/cbd-3375-ssh-key.pub`

## SSH Key Configuration
- **Algorithm**: RSA
- **Key Size**: 2048 bits
- **Format**: OpenSSH (public), PEM (private)

## VM Authentication
All VMs are configured with:
- **Password Authentication**: Disabled
- **SSH Key Authentication**: Enabled
- **Username**: sevastopol
- **SSH Key**: Automatically deployed from Key Vault

## How to Use SSH Keys

### 1. After Terraform Apply
```bash
# Get the SSH public key
terraform output ssh_public_key

# Get the key fingerprint
terraform output ssh_key_fingerprint

# Get the web VM public IP
terraform output web_vm_public_ip
```

### 2. SSH to Web VM (Jump Host)
```bash
# Use the local private key file
ssh -i ssh-keys/cbd-3375-ssh-key.pem sevastopol@<WEB_VM_PUBLIC_IP>

# Or use the key from Key Vault (after downloading)
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file temp-private-key.pem
chmod 600 temp-private-key.pem
ssh -i temp-private-key.pem sevastopol@<WEB_VM_PUBLIC_IP>
```

### 3. SSH to Backend/Database VMs (via Jump Host)
```bash
# First, copy the private key to the web VM
scp -i ssh-keys/cbd-3375-ssh-key.pem ssh-keys/cbd-3375-ssh-key.pem sevastopol@<WEB_VM_PUBLIC_IP>:~/

# SSH to web VM
ssh -i ssh-keys/cbd-3375-ssh-key.pem sevastopol@<WEB_VM_PUBLIC_IP>

# From web VM, SSH to backend/database VMs
ssh -i cbd-3375-ssh-key.pem sevastopol@<BACKEND_VM_PRIVATE_IP>
ssh -i cbd-3375-ssh-key.pem sevastopol@<DATABASE_VM_PRIVATE_IP>
```

## Key Vault Access

### View SSH Keys in Key Vault
```bash
# List all secrets
az keyvault secret list --vault-name CBD-3375-kv-unique123

# Get public key
az keyvault secret show --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-public --query value -o tsv

# Get private key (sensitive)
az keyvault secret show --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --query value -o tsv
```

### Download Keys from Key Vault
```bash
# Download private key
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file downloaded-private-key.pem
chmod 600 downloaded-private-key.pem

# Download public key
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-public --file downloaded-public-key.pub
```

## Security Features

### Key Vault Security
- **Access Control**: Only authenticated Azure users/service principals
- **Soft Delete**: 7-day retention for deleted secrets
- **Audit Logging**: All access is logged
- **Encryption**: Keys encrypted at rest and in transit

### SSH Key Security
- **Strong Encryption**: RSA 2048-bit keys
- **No Password Auth**: Password authentication disabled on all VMs
- **Private Key Protection**: Stored securely in Key Vault and local files with 600 permissions
- **Key Rotation**: Keys can be regenerated by re-running Terraform

### Network Security
- **Jump Host Pattern**: Private VMs only accessible via web VM
- **NSG Protection**: Network Security Groups control access
- **Private Subnets**: Backend/database VMs have no direct internet access

## Troubleshooting

### Permission Denied (publickey)
1. Check key file permissions: `chmod 600 ssh-keys/cbd-3375-ssh-key.pem`
2. Verify correct private key: `ssh-keygen -y -f ssh-keys/cbd-3375-ssh-key.pem`
3. Compare with public key: `cat ssh-keys/cbd-3375-ssh-key.pub`

### Key Vault Access Issues
1. Verify Azure CLI login: `az account show`
2. Check Key Vault permissions: `az keyvault show --name CBD-3375-kv-unique123`
3. List access policies: `az keyvault access-policy list --name CBD-3375-kv-unique123`

### VM Connection Issues
1. Check VM status: `az vm list --resource-group CBD-3375-resources --show-details`
2. Verify NSG rules: `az network nsg rule list --resource-group CBD-3375-resources --nsg-name CBD-3375-vnet-public-nsg`
3. Test connectivity: `nc -zv <VM_IP> 22`

## Key Rotation

To rotate SSH keys:
```bash
# Destroy and recreate Key Vault module
terraform destroy -target=module.key_vault
terraform apply -target=module.key_vault

# Update VMs with new keys (requires VM restart)
terraform apply
```

## Backup and Recovery

### Backup SSH Keys
```bash
# Create backup directory
mkdir -p ssh-key-backup/$(date +%Y%m%d)

# Backup from Key Vault
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-private --file ssh-key-backup/$(date +%Y%m%d)/private-key.pem
az keyvault secret download --vault-name CBD-3375-kv-unique123 --name cbd-3375-ssh-key-public --file ssh-key-backup/$(date +%Y%m%d)/public-key.pub

# Backup local files
cp ssh-keys/* ssh-key-backup/$(date +%Y%m%d)/
```

### Recovery
If local SSH key files are lost, they can be recovered from Key Vault using the download commands above.

## Important Notes

1. **Never commit SSH private keys to version control**
2. **The ssh-keys/ directory is excluded in .gitignore**
3. **Key Vault name must be globally unique**
4. **Private keys are marked as sensitive in Terraform outputs**
5. **SSH keys are automatically deployed to all VMs during creation**
6. **Key Vault access requires Azure authentication**
