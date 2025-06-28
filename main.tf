provider "azurerm" {
  features {}
  
  # Using Azure CLI authentication
  # Explicitly setting subscription ID for clarity
  subscription_id = "df7dc967-963c-4518-82bf-e1f24714f060"
  
  # Skip automatic resource provider registration
  # This is often needed for student accounts with limited permissions
  resource_provider_registrations = "none"
}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "networking" {
  source                           = "./modules/networking"
  vnet_name                       = var.vnet_name
  vnet_address_space              = var.vnet_address_space
  public_subnet_name              = var.public_subnet_name
  public_subnet_address_prefixes  = var.public_subnet_address_prefixes
  private_subnet_name             = var.private_subnet_name
  private_subnet_address_prefixes = var.private_subnet_address_prefixes
  web_vm_nic_name                 = var.web_vm_nic_name
  backend_vm_nic_name             = var.backend_vm_nic_name
  database_vm_nic_name            = var.database_vm_nic_name
  web_vm_public_ip_name           = var.web_vm_public_ip_name
  location                        = module.resource_group.location
  resource_group_name             = module.resource_group.name
  tags                            = var.tags
}

# Web Server VM (Public Subnet)
module "web_vm" {
  source                 = "./modules/virtual_machine"
  vm_name               = var.web_vm_name
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  vm_size               = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_id  = module.networking.web_vm_network_interface_id
  os_disk_name          = "${var.web_vm_name}-osdisk"
  os_disk_caching       = var.os_disk_caching
  storage_account_type  = var.storage_account_type
  image_publisher       = var.image_publisher
  image_offer           = var.image_offer
  image_sku             = var.image_sku
  image_version         = var.image_version
  custom_data           = local.web_vm_docker_script
  tags                  = merge(var.tags, { "Role" = "WebServer", "Docker" = "enabled" })
}

# Backend VM (Private Subnet)
module "backend_vm" {
  source                 = "./modules/virtual_machine"
  vm_name               = var.backend_vm_name
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  vm_size               = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_id  = module.networking.backend_vm_network_interface_id
  os_disk_name          = "${var.backend_vm_name}-osdisk"
  os_disk_caching       = var.os_disk_caching
  storage_account_type  = var.storage_account_type
  image_publisher       = var.image_publisher
  image_offer           = var.image_offer
  image_sku             = var.image_sku
  image_version         = var.image_version
  custom_data           = local.backend_vm_docker_script
  tags                  = merge(var.tags, { "Role" = "BackendServer", "Docker" = "enabled" })
}

# Database VM (Private Subnet) - No Docker needed for database
module "database_vm" {
  source                 = "./modules/virtual_machine"
  vm_name               = var.database_vm_name
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  vm_size               = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_id  = module.networking.database_vm_network_interface_id
  os_disk_name          = "${var.database_vm_name}-osdisk"
  os_disk_caching       = var.os_disk_caching
  storage_account_type  = var.storage_account_type
  image_publisher       = var.image_publisher
  image_offer           = var.image_offer
  image_sku             = var.image_sku
  image_version         = var.image_version
  custom_data           = null
  tags                  = merge(var.tags, { "Role" = "DatabaseServer" })
}