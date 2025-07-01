resource "azurerm_linux_virtual_machine" "this" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    var.network_interface_id,
  ]

  admin_password                  = var.admin_password
  disable_password_authentication = var.disable_password_authentication

  # SSH key configuration
  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != null ? [1] : []
    content {
      username   = var.admin_username
      public_key = var.ssh_public_key
    }
  }

  # Bootstrap script for Docker installation
  custom_data = var.custom_data

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.storage_account_type
    name                 = var.os_disk_name
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }

  tags = var.tags
}
