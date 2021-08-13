output "name" {
  value = "${var.name}"
}

output "ip_configuration" {
  # this is a synthesized map, to match what is produced by azurerm_firewall
  value = { "private_ip_address" = "${module.nic01.private_ip_address}" }
}

output "subnet_id" {
  value = "${module.egress_fwsubnet.id}"
}

output "subnet_name" {
  value = "${module.egress_fwsubnet.name}"
}

output "subnet_address_prefix" {
  value = "${module.egress_fwsubnet.address_prefix}"
}

output "subnet_ip_configurations" {
  value = "${module.egress_fwsubnet.ip_configurations}"
}

output "publicip_id" {
  value = "${azurerm_public_ip.egress_fwip.id}"
}

output "publicip_fqdn" {
  value = "${azurerm_public_ip.egress_fwip.fqdn}"
}

output "publicip_ip_address" {
  value = "${azurerm_public_ip.egress_fwip.ip_address}"
}

# In addition to being able to get this from the ip_configuration output, it is exported here as a convenience

output "private_ip_address" {
  value = "${module.nic01.private_ip_address}"
}

output "os_admin_username" {
  value = "${var.admin_username}"
}

output "os_admin_password" {
  value = "${random_string.password.result}"
}
