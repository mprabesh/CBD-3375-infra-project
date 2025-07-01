output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}

output "ssh_private_key_secret_id" {
  description = "ID of the SSH private key secret in Key Vault"
  value       = azurerm_key_vault_secret.ssh_private_key.id
}

output "ssh_public_key_secret_id" {
  description = "ID of the SSH public key secret in Key Vault"
  value       = azurerm_key_vault_secret.ssh_public_key.id
}

output "ssh_public_key" {
  description = "SSH public key content"
  value       = tls_private_key.ssh_key.public_key_openssh
}

output "ssh_private_key_pem" {
  description = "SSH private key in PEM format"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "ssh_key_fingerprint" {
  description = "SHA256 fingerprint of the SSH public key"
  value       = tls_private_key.ssh_key.public_key_fingerprint_sha256
}
