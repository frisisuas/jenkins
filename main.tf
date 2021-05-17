provider "azurerm" {
  features {}
}
variable "location" {
  type = string
  default = "westeurope"
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name = "RG-test-sql"
}

resource "azurerm_network_security_group" "nsg" {
  location = var.location
  name = "SQL-NSG"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_network_security_rule" "nsg_regla" {
  access = "Allow"
  direction = "Inbound"
  name = "rdp-casa"
  network_security_group_name = azurerm_network_security_group.nsg.name
  priority = 1100
  protocol = "Tcp"
  resource_group_name = azurerm_resource_group.rg.name
  source_port_range = "*"
  destination_port_range = "3389"
  destination_address_prefix = "*"
  source_address_prefix = "2.138.59.206"
}
resource "azurerm_virtual_network" "vNET" {
  address_space = ["10.0.0.0/16"]
  location = var.location
  name = "vnet"
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "subnet" {
  name = "subnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vNET.name
  address_prefixes = [
  "10.0.10.0/24"
  ]
}

resource "azurerm_public_ip" "pip" {
  allocation_method = "Dynamic"
  location = var.location
  name = "pip"
  resource_group_name = azurerm_resource_group.rg.name
  idle_timeout_in_minutes = 30
}
resource "azurerm_network_interface" "nic" {
  location = var.location
  name = "nic"
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.pip.id
    name = "vm-sql-ip"
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_windows_virtual_machine" "vm_sql" {
  admin_password = "IY@HfJkwQNB"
  admin_username = "Azureadmin"
  location = var.location
  name = "vm-sql"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  resource_group_name =azurerm_resource_group.rg.name
  size = "Standard_DS3_v2"
  source_image_reference {
    offer = "SQL2016SP2-WS2016"
    publisher = "MicrosoftSQLServer"
    sku = "SQLDEV"
    version = "latest"
  }
  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
