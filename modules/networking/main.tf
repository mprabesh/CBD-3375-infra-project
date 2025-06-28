resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Public Subnet for app servers (with internet access)
resource "azurerm_subnet" "public" {
  name                 = var.public_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.public_subnet_address_prefixes
}

# Private Subnet for database/backend services (no direct internet access)
resource "azurerm_subnet" "private" {
  name                 = var.private_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.private_subnet_address_prefixes
}

# Internet Gateway equivalent - NAT Gateway for private subnet outbound access
resource "azurerm_public_ip" "nat_gateway" {
  name                = "${var.vnet_name}-nat-gateway-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = "${var.vnet_name}-nat-gateway"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name               = "Standard"
  idle_timeout_in_minutes = 10

  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

# Public IP for the web server VM in public subnet
resource "azurerm_public_ip" "web_vm" {
  name                = var.web_vm_public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# Network Interface for Web Server VM (placed in public subnet)
resource "azurerm_network_interface" "web_vm" {
  name                = var.web_vm_nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_vm.id
  }

  tags = var.tags
}

# Network Interface for Backend VM (placed in private subnet)
resource "azurerm_network_interface" "backend_vm" {
  name                = var.backend_vm_nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

# Network Interface for Database VM (placed in private subnet)
resource "azurerm_network_interface" "database_vm" {
  name                = var.database_vm_nic_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}
