resource "azurerm_public_ip" "node" {
  count               = var.num
  name                = "${var.name}-public-ip-${count.index}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "node" {
  count               = var.num
  name                = "${var.name}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "nicConfiguration"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = element(azurerm_public_ip.node.*.id, count.index)
  }
}

resource "azurerm_network_interface_security_group_association" "nisga" {
  count                     = length(azurerm_network_interface.node)
  network_interface_id      = azurerm_network_interface.node[count.index].id
  network_security_group_id = var.security_group_id
}

resource "azurerm_linux_virtual_machine" "node" {
  count                 = var.num
  name                  = "${var.name}-node-${count.index}"
  admin_username        = "azureuser"
  computer_name         = "${var.name}-node-${count.index}"
  location              = var.location
  availability_set_id   = var.availability_set_id
  resource_group_name   = var.resource_group_name
  network_interface_ids = [element(azurerm_network_interface.node.*.id, count.index)]
  size                  = var.size

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.name}-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.public_key
  }

  tags = {
    Name     = "${var.name}-node-${count.index}"
    K8sRoles = var.roles
  }

  provisioner "remote-exec" {
    inline = [
      "curl -sL https://releases.rancher.com/install-docker/19.03.sh | sudo sh",
      "sudo usermod -aG docker azureuser"
    ]
    connection {
      host        = self.public_ip_address
      type        = "ssh"
      user        = "azureuser"
      private_key = var.private_key
    }
  }
}
