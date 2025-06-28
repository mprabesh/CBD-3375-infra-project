variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the virtual machine"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true
}

variable "network_interface_id" {
  description = "ID of the network interface to attach to the VM"
  type        = string
}

variable "os_disk_name" {
  description = "Name of the OS disk"
  type        = string
}

variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
}

variable "storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
}

variable "image_publisher" {
  description = "Publisher of the VM image"
  type        = string
}

variable "image_offer" {
  description = "Offer of the VM image"
  type        = string
}

variable "image_sku" {
  description = "SKU of the VM image"
  type        = string
}

variable "image_version" {
  description = "Version of the VM image"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the virtual machine"
  type        = map(string)
  default     = {}
}

variable "custom_data" {
  description = "Base64-encoded custom data for VM bootstrap (cloud-init script)"
  type        = string
  default     = null
}
