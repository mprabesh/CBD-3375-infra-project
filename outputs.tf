output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.resource_group.location
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = module.networking.vnet_address_space
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = module.networking.public_subnet_name
}

output "public_subnet_address_prefixes" {
  description = "Address prefixes of the public subnet"
  value       = module.networking.public_subnet_address_prefixes
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = module.networking.private_subnet_name
}

output "private_subnet_address_prefixes" {
  description = "Address prefixes of the private subnet"
  value       = module.networking.private_subnet_address_prefixes
}

# Web Server VM Outputs
output "web_vm_name" {
  description = "Name of the web virtual machine"
  value       = module.web_vm.vm_name
}

output "web_vm_public_ip" {
  description = "Public IP address of the web virtual machine"
  value       = module.networking.web_vm_public_ip_address
}

output "web_vm_private_ip" {
  description = "Private IP address of the web virtual machine"
  value       = module.networking.web_vm_private_ip
}

# Backend Server VM Outputs
output "backend_vm_name" {
  description = "Name of the backend virtual machine"
  value       = module.backend_vm.vm_name
}

output "backend_vm_private_ip" {
  description = "Private IP address of the backend virtual machine"
  value       = module.networking.backend_vm_private_ip
}

# Database Server VM Outputs
output "database_vm_name" {
  description = "Name of the database virtual machine"
  value       = module.database_vm.vm_name
}

output "database_vm_private_ip" {
  description = "Private IP address of the database virtual machine"
  value       = module.networking.database_vm_private_ip
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP for private subnet outbound access"
  value       = module.networking.nat_gateway_public_ip
}

output "vm_admin_username" {
  description = "Admin username for all virtual machines"
  value       = module.web_vm.vm_admin_username
}

# Network Security Group Outputs
output "public_nsg_name" {
  description = "Name of the public subnet Network Security Group"
  value       = module.networking.public_nsg_name
}

output "private_nsg_name" {
  description = "Name of the private subnet Network Security Group"
  value       = module.networking.private_nsg_name
}

# Key Vault Outputs
output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = module.key_vault.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = module.key_vault.key_vault_uri
}

output "ssh_public_key" {
  description = "SSH public key content"
  value       = module.key_vault.ssh_public_key
}

output "ssh_key_fingerprint" {
  description = "SHA256 fingerprint of the SSH public key"
  value       = module.key_vault.ssh_key_fingerprint
}

output "ssh_private_key_secret_name" {
  description = "Name of the SSH private key secret in Key Vault"
  value       = "${var.ssh_key_name}-private"
}

output "ssh_public_key_secret_name" {
  description = "Name of the SSH public key secret in Key Vault"
  value       = "${var.ssh_key_name}-public"
}

# Security Information
output "secure_ssh_access_command" {
  description = "Command to securely download and use SSH key from Key Vault"
  value       = "az keyvault secret download --vault-name ${var.key_vault_name} --name ${var.ssh_key_name}-private --file temp-key.pem && chmod 600 temp-key.pem"
}

output "ssh_cleanup_command" {
  description = "Command to securely clean up temporary SSH key files"
  value       = "rm temp-key.pem"
}

output "security_mode" {
  description = "Current SSH key security mode"
  value       = var.create_local_ssh_files ? "DEVELOPMENT (Local files created - Less Secure)" : "PRODUCTION (Key Vault only - Most Secure)"
}
