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

output "subnet_name" {
  description = "Name of the subnet"
  value       = module.networking.subnet_name
}

output "subnet_address_prefixes" {
  description = "Address prefixes of the subnet"
  value       = module.networking.subnet_address_prefixes
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = module.networking.network_interface_id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.virtual_machine.vm_name
}

output "vm_admin_username" {
  description = "Admin username of the virtual machine"
  value       = module.virtual_machine.vm_admin_username
}

output "vm_private_ip" {
  description = "Private IP address of the virtual machine"
  value       = module.networking.network_interface_private_ip
}

output "vm_public_ip" {
  description = "Public IP address of the virtual machine"
  value       = module.networking.public_ip_address
}
