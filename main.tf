resource "azurerm_resource_group" "this" {
  name     = "${var.prefix_display_name}-ResourceGroup"
  location = var.region
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix_display_name}-VirtualNetwork"
  address_space       = [var.vpc_cidr_block]
  location            = var.region
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "${var.prefix_display_name}-Subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidr_block]
}

resource "azurerm_public_ip" "this" {
  name                = "${var.prefix_display_name}-PublicIp"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix_display_name}-NetworkSecurityGroup"
  location            = var.region
  resource_group_name = azurerm_resource_group.this.name

  dynamic "security_rule" {
    iterator = rule
    for_each = toset(var.ingress_allowed_tcp)
    content {
      name                       = "${var.prefix_display_name} Inbound TCP ${rule.value}"
      priority                   = 1001+index(var.ingress_allowed_tcp, rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = rule.value
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  dynamic "security_rule" {
    iterator = rule
    for_each = toset(var.ingress_allowed_udp)
    content {
      name                       = "${var.prefix_display_name} Inbound UDP ${rule.value}"
      priority                   = 2001+index(var.ingress_allowed_udp, rule.value)
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_range     = rule.value
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_network_interface" "this" {
  name                = "${var.prefix_display_name}-NIC"
  location            = var.region
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "${var.prefix_display_name}-NicConfiguration"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}


resource "random_id" "this" {
  keepers = {
    resource_group = azurerm_resource_group.this.name
  }

  byte_length = 8
}


resource "azurerm_storage_account" "this" {
  name                     = "diag${random_id.this.hex}"
  resource_group_name      = azurerm_resource_group.this.name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_managed_disk" "this" {
  name                 = "${var.prefix_display_name}-Attached"
  location             = azurerm_resource_group.this.location
  resource_group_name  = azurerm_resource_group.this.name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.storage_size_in_gbs
}

resource "azurerm_virtual_machine_data_disk_attachment" "this" {
  managed_disk_id    = azurerm_managed_disk.this.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_linux_virtual_machine" "this" {
  name                  = "${var.prefix_display_name}-Instance"
  location              = var.region
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.this.id]
  size                  = var.instance_size

  os_disk {
    name                 = "${var.prefix_display_name}-Disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.storage_size_in_gbs
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal-daily"
    sku       = "20_04-daily-lts-gen2"
    version   = "latest"
  }

  computer_name                   = var.prefix_display_name
  admin_username                  = "ubuntu"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "ubuntu"
    public_key = file(var.ssh_public_key_path)
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.this.primary_blob_endpoint
  }
}

resource "cloudflare_record" "instance_name" {
  zone_id = var.cloudflare_zone_id
  name    = var.cloudflare_instance_name
  value   = azurerm_linux_virtual_machine.this.public_ip_address
  type    = "A"
  proxied = false
}