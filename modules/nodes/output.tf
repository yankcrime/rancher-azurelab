
output "nodes" {
  value = [
    for instance in azurerm_linux_virtual_machine.node : {
      public_ip  = instance.public_ip_address
      private_ip = instance.private_ip_address
      roles      = split(",", instance.tags.K8sRoles)
    }
  ]
}
