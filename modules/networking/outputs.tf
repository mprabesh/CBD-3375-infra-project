output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.this.address_space
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = azurerm_subnet.public.name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = azurerm_subnet.public.id
}

output "public_subnet_address_prefixes" {
  description = "Address prefixes of the public subnet"
  value       = azurerm_subnet.public.address_prefixes
}

output "private_subnet_name" {
  description = "Name of the private subnet"
  value       = azurerm_subnet.private.name
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = azurerm_subnet.private.id
}

output "private_subnet_address_prefixes" {
  description = "Address prefixes of the private subnet"
  value       = azurerm_subnet.private.address_prefixes
}

output "web_vm_network_interface_id" {
  description = "ID of the web VM network interface"
  value       = azurerm_network_interface.web_vm.id
}

output "web_vm_private_ip" {
  description = "Private IP address of the web VM network interface"
  value       = azurerm_network_interface.web_vm.private_ip_address
}

output "backend_vm_network_interface_id" {
  description = "ID of the backend VM network interface"
  value       = azurerm_network_interface.backend_vm.id
}

output "backend_vm_private_ip" {
  description = "Private IP address of the backend VM network interface"
  value       = azurerm_network_interface.backend_vm.private_ip_address
}

output "database_vm_network_interface_id" {
  description = "ID of the database VM network interface"
  value       = azurerm_network_interface.database_vm.id
}

output "database_vm_private_ip" {
  description = "Private IP address of the database VM network interface"
  value       = azurerm_network_interface.database_vm.private_ip_address
}

output "web_vm_public_ip_address" {
  description = "Public IP address of the web VM"
  value       = azurerm_public_ip.web_vm.ip_address
}

output "web_vm_public_ip_id" {
  description = "ID of the web VM public IP"
  value       = azurerm_public_ip.web_vm.id
}

output "nat_gateway_public_ip" {
  description = "NAT Gateway public IP address"
  value       = azurerm_public_ip.nat_gateway.ip_address
}
