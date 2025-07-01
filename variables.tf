variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "CBD-3375-resources"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
  default     = "CBD-3375-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
  default     = "public-subnet"
}

variable "public_subnet_address_prefixes" {
  description = "Address prefixes for the public subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_name" {
  description = "Name of the private subnet"
  type        = string
  default     = "private-subnet"
}

variable "private_subnet_address_prefixes" {
  description = "Address prefixes for the private subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
}

variable "network_interface_name" {
  description = "Name of the network interface"
  type        = string
  default     = "ghost-nic"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "CBD-3375-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "sevastopol"
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true
  default     = "sevastopol1234!"
}

variable "os_disk_name" {
  description = "Name of the OS disk"
  type        = string
  default     = "CBD-3375-osdisk"
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
  default     = "public-ip"
}

# VM Network Interface Names
variable "web_vm_nic_name" {
  description = "Name of the web VM network interface"
  type        = string
  default     = "web-vm-nic"
}

variable "backend_vm_nic_name" {
  description = "Name of the backend VM network interface"
  type        = string
  default     = "backend-vm-nic"
}

variable "database_vm_nic_name" {
  description = "Name of the database VM network interface"
  type        = string
  default     = "database-vm-nic"
}

variable "web_vm_public_ip_name" {
  description = "Name of the web VM public IP"
  type        = string
  default     = "web-vm-public-ip"
}

# VM Configuration
variable "web_vm_name" {
  description = "Name of the web virtual machine"
  type        = string
  default     = "web-vm"
}

variable "backend_vm_name" {
  description = "Name of the backend virtual machine"
  type        = string
  default     = "backend-vm"
}

variable "database_vm_name" {
  description = "Name of the database virtual machine"
  type        = string
  default     = "database-vm"
}

# Azure Key Vault Configuration
variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "CBD-3375-kv"
}

variable "key_vault_sku_name" {
  description = "SKU name for the Key Vault"
  type        = string
  default     = "standard"
}

variable "ssh_key_name" {
  description = "Name of the SSH key to store in Key Vault"
  type        = string
  default     = "cbd-3375-ssh-key"
}

variable "ssh_key_size" {
  description = "Size of the RSA SSH key in bits"
  type        = number
  default     = 2048
}

variable "create_local_ssh_files" {
  description = "Whether to create local SSH key files (SECURITY WARNING: Not recommended for production)"
  type        = bool
  default     = false
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