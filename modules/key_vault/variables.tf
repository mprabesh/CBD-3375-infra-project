variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "key_vault_sku_name" {
  description = "SKU name for the Key Vault"
  type        = string
  default     = "standard"
}

variable "ssh_key_name" {
  description = "Name of the SSH key to store in Key Vault"
  type        = string
}

variable "ssh_key_size" {
  description = "Size of the RSA SSH key in bits"
  type        = number
  default     = 2048
}

variable "tags" {
  description = "Tags to apply to the Key Vault resources"
  type        = map(string)
  default     = {}
}
