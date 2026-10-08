resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.prefix}"
  location            = azurerm_resource_group.tutor.location
  resource_group_name = azurerm_resource_group.tutor.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags
}

resource "azurerm_subnet" "edge" {
  name                 = "snet-edge"
  resource_group_name  = azurerm_resource_group.tutor.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.edge_subnet_cidr]
}

resource "azurerm_network_security_group" "edge" {
  name                = "nsg-${var.prefix}-edge"
  location            = azurerm_resource_group.tutor.location
  resource_group_name = azurerm_resource_group.tutor.name

  security_rule {
    name                       = "allow-https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-tailscale-direct" # optional; avoids the DERP relay
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "41641"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # NO port 22 / 80. The built-in DenyAllInBound rule (priority 65500) drops everything else.
  tags = local.tags
}

resource "azurerm_public_ip" "edge" {
  name                = "pip-${var.prefix}-edge"
  location            = azurerm_resource_group.tutor.location
  resource_group_name = azurerm_resource_group.tutor.name
  allocation_method   = "Static" # DuckDNS points here once; never changes
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "edge" {
  name                = "nic-${var.prefix}-edge"
  location            = azurerm_resource_group.tutor.location
  resource_group_name = azurerm_resource_group.tutor.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.edge.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.edge.id
  }

  tags = local.tags
}

resource "azurerm_network_interface_security_group_association" "edge" {
  network_interface_id      = azurerm_network_interface.edge.id
  network_security_group_id = azurerm_network_security_group.edge.id
}
