terraform {
  backend "azurerm" {
    resource_group_name  = "jmtfrg"
    storage_account_name = "jmtfststac"
    container_name       = "jmtfststaccontainer"
    key                  = "jmtfststaccontainer.tfstate"
  }
}

provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you're using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

data "azurerm_client_config" "current" {}

#Create Resource Group
resource "azurerm_resource_group" "jm-tftest" {
  name     = "jm-tftest"
  location = "eastus2"
}

#Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "jm-tftest-vnet"
  address_space       = ["192.168.0.0/16"]
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.jm-tftest.name
}

# Create Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.jm-tftest.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "192.168.0.0/24"
}

# Define new oublic IP address
resource "azurerm_public_ip" "myvm1publicip" {
  name                = "myvm1publicip"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.jm-tftest.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# Define Network Interface
resource "azurerm_network_interface" "myvm1nic" {
  name                = "myvm1nic"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.jm-tftest.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.publicip.id
  }
}

# Define VM
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "myvm1"
  location              = "eastus2"
  resource_group_name   = azurerm_resource_group.jm-tftest.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_B1s"
  admin_username        = "adminuser"
  admin_password        = "Password123!"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}
