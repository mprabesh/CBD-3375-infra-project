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
