variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
}

variable "public_subnet_address_prefixes" {
  description = "Address prefixes for the public subnet"
  type        = list(string)
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
}

variable "private_subnet_address_prefixes" {
  description = "Address prefixes for the private subnet"
  type        = list(string)
}

variable "web_vm_nic_name" {
  description = "Name of the web VM network interface"
  type        = string
}

variable "backend_vm_nic_name" {
  description = "Name of the backend VM network interface"
  type        = string
}

variable "database_vm_nic_name" {
  description = "Name of the database VM network interface"
  type        = string
}

variable "web_vm_public_ip_name" {
  description = "Name of the web VM public IP"
  type        = string
}

variable "location" {
  description = "Azure region for networking resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "tags" {
  description = "Tags to apply to networking resources"
  type        = map(string)
  default     = {}
}
