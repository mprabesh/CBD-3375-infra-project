# Get current client configuration
data "azurerm_client_config" "current" {}

# Generate RSA SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = var.ssh_key_size
}

# Create Azure Key Vault
resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku_name
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Enable access for current user/service principal
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
      "Release",
      "Rotate",
      "GetRotationPolicy",
      "SetRotationPolicy"
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set"
    ]

    certificate_permissions = [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update"
    ]
  }

  tags = var.tags
}

# Store SSH private key in Key Vault
resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "${var.ssh_key_name}-private"
  value        = tls_private_key.ssh_key.private_key_pem
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]

  tags = merge(var.tags, {
    "Type" = "SSH Private Key"
  })
}

# Store SSH public key in Key Vault
resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "${var.ssh_key_name}-public"
  value        = tls_private_key.ssh_key.public_key_openssh
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_key_vault.this]

  tags = merge(var.tags, {
    "Type" = "SSH Public Key"
  })
}

# ================================================================================
#                            SSH KEY LOCAL FILE MANAGEMENT
# ================================================================================
#
# IMPLEMENTATION EVOLUTION:
# 1. Original: Automatic local file creation (always created files)
# 2. Enhanced: Conditional creation with security controls (current default)
# 3. Future: Key Vault-only with no local files option
#
# SECURITY CONSIDERATIONS:
# - Local files: Convenient but potential security risk
# - Key Vault only: Most secure, requires Azure CLI for access
# - Conditional: Best of both worlds with explicit choice
#
# ================================================================================

# SECURITY WARNING: Local SSH key files are only created if explicitly enabled
# For production environments, keep create_local_ssh_files = false
# Access keys securely from Key Vault using:
# az keyvault secret download --vault-name <vault-name> --name <secret-name> --file temp-key.pem

# APPROACH 1: SECURE - Key Vault Only (Default)
# SSH keys are only stored in Azure Key Vault with no local files
# Use temporary download pattern for secure access
resource "local_file" "ssh_private_key" {
  count           = var.create_local_ssh_files ? 1 : 0
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/ssh-keys/${var.ssh_key_name}.pem"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  count    = var.create_local_ssh_files ? 1 : 0
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.root}/ssh-keys/${var.ssh_key_name}.pub"
}

# APPROACH 2: DEVELOPMENT - Local Files (Commented for Reference)
# This was the original implementation - creates local SSH key files automatically
# Uncomment and remove the conditional logic above if you want automatic local files
# WARNING: This approach has security implications - see SECURE_SSH_GUIDE.md

# resource "local_file" "ssh_private_key" {
#   content         = tls_private_key.ssh_key.private_key_pem
#   filename        = "${path.root}/ssh-keys/${var.ssh_key_name}.pem"
#   file_permission = "0600"
# }
# 
# resource "local_file" "ssh_public_key" {
#   content  = tls_private_key.ssh_key.public_key_openssh
#   filename = "${path.root}/ssh-keys/${var.ssh_key_name}.pub"
# }
