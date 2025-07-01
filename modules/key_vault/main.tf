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

# Create a local file with the private key for immediate use (optional)
resource "local_file" "ssh_private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.root}/ssh-keys/${var.ssh_key_name}.pem"
  file_permission = "0600"
}

# Create a local file with the public key for immediate use (optional)
resource "local_file" "ssh_public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = "${path.root}/ssh-keys/${var.ssh_key_name}.pub"
}
