# Secure SSH Key Usage Guide

## 🔒 Enhanced Security Implementation

This infrastructure now uses **Key Vault-only SSH key storage** by default for maximum security.

### 🛡️ Security Features

- ✅ **No local SSH key files** created by default
- ✅ **Key Vault-only storage** with encryption at rest
- ✅ **Azure RBAC access control** for key access
- ✅ **Audit logging** for all key access
- ✅ **Temporary download** pattern for key usage

### 🔑 How to Access SSH Keys

#### Method 1: Download from Key Vault (Recommended)
```bash
# Download private key temporarily
az keyvault secret download \
  --vault-name CBD-3375-kv-unique123 \
  --name cbd-3375-ssh-key-private \
  --file temp-private-key.pem

# Set correct permissions
chmod 600 temp-private-key.pem

# Use for SSH connection
ssh -i temp-private-key.pem sevastopol@<VM_PUBLIC_IP>

# IMPORTANT: Delete the file after use
rm temp-private-key.pem
```

#### Method 2: Use Terraform Output (Alternative)
```bash
# Get private key from Terraform (sensitive output)
terraform output -raw ssh_private_key_pem > temp-key.pem
chmod 600 temp-key.pem
ssh -i temp-key.pem sevastopol@<VM_PUBLIC_IP>
rm temp-key.pem  # Always clean up
```

#### Method 3: One-liner for Temporary Access
```bash
# Download, use, and delete in one command
az keyvault secret show \
  --vault-name CBD-3375-kv-unique123 \
  --name cbd-3375-ssh-key-private \
  --query value -o tsv > temp-key.pem && \
chmod 600 temp-key.pem && \
ssh -i temp-key.pem sevastopol@$(terraform output -raw web_vm_public_ip) && \
rm temp-key.pem
```

### 🚨 Development Mode (Original Approach - Less Secure)

The original implementation automatically created local SSH key files. This approach is still available but disabled by default for security reasons.

#### Option A: Enable via Variable (Recommended for Development)
```bash
# Set in terraform.tfvars
create_local_ssh_files = true

# Then apply
terraform apply
```

#### Option B: Modify Code Directly (Alternative Method)
If you prefer the original automatic approach, you can modify `modules/key_vault/main.tf`:

1. Comment out the conditional resources (lines with `count = var.create_local_ssh_files ? 1 : 0`)
2. Uncomment the "APPROACH 2" section at the bottom of the file

```terraform
# Remove conditional logic and use original automatic approach
resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/ssh-keys/${var.ssh_key_name}.pem"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.root}/ssh-keys/${var.ssh_key_name}.pub"
}
```

**Both approaches will create:**
- `ssh-keys/cbd-3375-ssh-key.pem` (private key, 600 permissions)
- `ssh-keys/cbd-3375-ssh-key.pub` (public key)

**⚠️ Security Warning:** Local files can be:
- Accidentally committed to version control
- Exposed through backups or system compromises
- Accessed by malware or other users

### 📋 Complete SSH Workflow

#### 1. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

#### 2. Get VM Information
```bash
# Get public IP for web VM
terraform output web_vm_public_ip

# Get private IPs for backend/database VMs
terraform output backend_vm_private_ip
terraform output database_vm_private_ip
```

#### 3. SSH to Web VM (Jump Host)
```bash
# Download SSH key from Key Vault
az keyvault secret download \
  --vault-name CBD-3375-kv-unique123 \
  --name cbd-3375-ssh-key-private \
  --file temp-key.pem
chmod 600 temp-key.pem

# SSH to web VM
ssh -i temp-key.pem sevastopol@<WEB_VM_PUBLIC_IP>
```

#### 4. Access Private VMs (from Web VM)
```bash
# Copy the private key to web VM for jump access
scp -i temp-key.pem temp-key.pem sevastopol@<WEB_VM_PUBLIC_IP>:~/temp-key.pem

# SSH to web VM
ssh -i temp-key.pem sevastopol@<WEB_VM_PUBLIC_IP>

# From web VM, SSH to private VMs
chmod 600 ~/temp-key.pem
ssh -i ~/temp-key.pem sevastopol@<BACKEND_VM_PRIVATE_IP>
ssh -i ~/temp-key.pem sevastopol@<DATABASE_VM_PRIVATE_IP>

# Clean up the key on web VM
rm ~/temp-key.pem
```

#### 5. Clean Up Local Environment
```bash
# Always remove temporary key files
rm temp-key.pem
```

### 🔐 Key Vault Operations

#### List All Secrets
```bash
az keyvault secret list --vault-name CBD-3375-kv-unique123
```

#### View Key Information
```bash
# Get public key (safe to view)
az keyvault secret show \
  --vault-name CBD-3375-kv-unique123 \
  --name cbd-3375-ssh-key-public \
  --query value -o tsv

# Get key fingerprint
terraform output ssh_key_fingerprint
```

#### Access Control
```bash
# List access policies
az keyvault access-policy list --name CBD-3375-kv-unique123

# Check your access
az keyvault secret list --vault-name CBD-3375-kv-unique123
```

### 🛠️ Troubleshooting

#### Permission Denied Issues
```bash
# Check if key file has correct permissions
ls -la temp-key.pem
# Should show: -rw------- (600 permissions)

# Fix permissions if needed
chmod 600 temp-key.pem

# Verify the key format
head -1 temp-key.pem
# Should show: -----BEGIN RSA PRIVATE KEY-----
```

#### Key Vault Access Issues
```bash
# Check Azure CLI authentication
az account show

# Verify Key Vault access
az keyvault show --name CBD-3375-kv-unique123

# Test secret access
az keyvault secret list --vault-name CBD-3375-kv-unique123
```

#### SSH Connection Issues
```bash
# Test SSH with verbose output
ssh -v -i temp-key.pem sevastopol@<VM_IP>

# Check VM status
az vm list --resource-group CBD-3375-resources --show-details

# Verify NSG rules allow SSH
az network nsg rule list \
  --resource-group CBD-3375-resources \
  --nsg-name CBD-3375-vnet-public-nsg
```

### 📊 Security Benefits

| Feature | Local Files | Key Vault Only |
|---------|------------|----------------|
| File System Exposure | ❌ High Risk | ✅ No Risk |
| Version Control Risk | ❌ Possible | ✅ Impossible |
| Access Auditing | ❌ None | ✅ Full Audit |
| Encryption at Rest | ❌ OS Dependent | ✅ Always |
| Access Control | ❌ File Permissions | ✅ Azure RBAC |
| Key Rotation | ❌ Manual Process | ✅ Automated |

### 🎯 Best Practices

1. **Always use Key Vault-only mode** for production
2. **Download keys temporarily** only when needed
3. **Delete temporary files** immediately after use
4. **Use one-liner commands** to minimize key exposure time
5. **Monitor Key Vault access logs** for unauthorized access
6. **Rotate SSH keys regularly** by re-running Terraform
7. **Never commit SSH keys** to version control
8. **Use strong access policies** on Key Vault

This approach provides enterprise-grade security while maintaining operational flexibility!
