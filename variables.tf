variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "example-resources"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "example-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "example-subnet"
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "network_interface_name" {
  description = "Name of the network interface"
  type        = string
  default     = "example-nic"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "example-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true
  default     = "P@ssword1234!"
}

variable "os_disk_name" {
  description = "Name of the OS disk"
  type        = string
  default     = "example-osdisk"
}

variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
  default     = "ReadWrite"
}

variable "storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "Standard_LRS"
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
  default     = "Canonical"
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
  default     = "0001-com-ubuntu-server-focal"
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
  default     = "20_04-lts"
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "public_ip_name" {
  description = "Name of the public IP"
  type        = string
  default     = "example-public-ip"
}

# Azure Authentication Variables (not needed when using Azure CLI)
# variable "client_id" {
#   description = "Azure Service Principal Client ID"
#   type        = string
#   sensitive   = true
# }

# variable "client_secret" {
#   description = "Azure Service Principal Client Secret"
#   type        = string
#   sensitive   = true
# }

# variable "tenant_id" {
#   description = "Azure Tenant ID"
#   type        = string
#   sensitive   = true
# }

# variable "subscription_id" {
#   description = "Azure Subscription ID"
#   type        = string
#   sensitive   = true
# }