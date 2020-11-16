resource "azurerm_resource_group" "resource_group" {
  name     = var.resource_group_name
  location = var.location
}

module "vnet-main" {
  source              = "Azure/vnet/azurerm"
  version             = "2.3.0"
  resource_group_name = azurerm_resource_group.resource_group.name
  vnet_name           = var.resource_group_name
  address_space       = var.vnet_cidr_range
  subnet_prefixes     = var.subnet_prefixes
  subnet_names        = var.subnet_names
  nsg_ids             = {}

  tags = {
    engineer = var.engineer

  }
}

resource "azurerm_network_security_group" "rke_nsg" {
  name                = "rke_nsg_allow_all"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  security_rule {
    name                       = "allow_all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    engineer = var.engineer

  }
}

resource "azurerm_availability_set" "avset" {
  name                         = var.avset_name
  location                     = var.location
  resource_group_name          = azurerm_resource_group.resource_group.name
  platform_fault_domain_count  = 3
  platform_update_domain_count = 3
  managed                      = true
}

resource "tls_private_key" "bootstrap_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "bootstrap_private_key" {
  content         = tls_private_key.bootstrap_private_key.private_key_pem
  filename        = "bootstrap_private_key.pem"
  file_permission = "0500"
}

module "rke-control" {
  source = "./modules/nodes"

  num                 = var.num_control
  name                = "control"
  roles               = "controlplane,etcd"
  subnet_id           = module.vnet-main.vnet_subnets[0]
  security_group_id   = azurerm_network_security_group.rke_nsg.id
  availability_set_id = azurerm_availability_set.avset.id
  resource_group_name = azurerm_resource_group.resource_group.name
  public_key          = tls_private_key.bootstrap_private_key.public_key_openssh
  private_key         = tls_private_key.bootstrap_private_key.private_key_pem

}

module "rke-worker" {
  source = "./modules/nodes"

  num                 = var.num_worker
  name                = "worker"
  roles               = "worker"
  subnet_id           = module.vnet-main.vnet_subnets[0]
  security_group_id   = azurerm_network_security_group.rke_nsg.id
  availability_set_id = azurerm_availability_set.avset.id
  resource_group_name = azurerm_resource_group.resource_group.name
  public_key          = tls_private_key.bootstrap_private_key.public_key_openssh
  private_key         = tls_private_key.bootstrap_private_key.private_key_pem

}

locals {
  nodes = [
    for instance in flatten([[module.rke-control.nodes], [module.rke-worker.nodes]]) : {
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      roles      = instance.roles
    }
  ]
}

resource "local_file" "clusteryml" {
  content  = templatefile("cluster.yml.tpl", { nodes = local.nodes, kubernetes_version = var.kubernetes_version })
  filename = "cluster.yml"
}
