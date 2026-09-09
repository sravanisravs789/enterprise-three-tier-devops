
# 1. Define the Microsoft Azure Provider version mapping
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Establish the Enterprise Resource Group Grouping
resource "azurerm_resource_group" "devops_rg" {
  name     = "enterprise-devops-rg"
  location = "East US"
}

# 3. Provision the Isolated Virtual Network Space
resource "azurerm_virtual_network" "devops_vnet" {
  name                = "devops-secure-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
}

# 4. Carve out a Public Subnet for our Compute Tier
resource "azurerm_subnet" "devops_subnet" {
  name                 = "devops-public-subnet"
  resource_group_name  = azurerm_resource_group.devops_rg.name
  virtual_network_name = azurerm_virtual_network.devops_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 5. Provision the Cloud Firewall (Network Security Group)
resource "azurerm_network_security_group" "devops_nsg" {
  name                = "devops-firewall-nsg"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Frontend-8080"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 6. Bind the Firewall directly to the Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.devops_subnet.id
  network_security_group_id = azurerm_network_security_group.devops_nsg.id
}

# 7. Allocate a Dedicated Public IP Address Object
resource "azurerm_public_ip" "devops_pip" {
  name                = "devops-server-ip"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  allocation_method   = "Dynamic"
}

# 8. Provision the Virtual Network Interface Card (NIC)
resource "azurerm_network_interface" "devops_nic" {
  name                = "devops-server-nic"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.devops_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devops_pip.id
  }
}

# 9. Provision the Linux Virtual Machine Server Instance
resource "azurerm_linux_virtual_machine" "devops_vm" {
  name                = "devops-production-server"
  resource_group_name = "enterprise-devops-rg"
  location            = "East US"
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.devops_nic.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}
