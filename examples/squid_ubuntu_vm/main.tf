locals {
  location                                             = "centralus"
  admin_username                                       = "osadmin"
  squid_rules                                          = [
                                                           "acl allowed_domains dstdomain .google.com",
                                                           "acl allowed_domains dstdomain azure.archive.ubuntu.com",
                                                           "acl allowed_domains dstdomain security.ubuntu.com",
                                                           "http_access allow localnet allowed_domains"
                                                          ]
}

data "template_file" "config_environment_file" {
  template                                             = "${file("${path.module}/config_environment.sh.tpl")}"
  vars = {
    proxy_ip                                           = "${module.egress_proxy.private_ip_address}"
  }
}

data "template_cloudinit_config" "config" {
  # cloudinit has a limit of 16kb (after gzip'd)
  gzip                                                 = true
  base64_encode                                        = true
  part {
    filename                                           = "/etc/environment"
    content_type                                       = "text/x-shellscript"
    content                                            = "${data.template_file.config_environment_file.rendered}"
  }
}

################################################################################
#  MODULES & RESOURCES
################################################################################

module "random_name" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/terraform_common//terraform_module/random_name?ref=v1.2.1"
}

module "rg01" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/azure_resource_group?ref=v2.0.0"
  name                                                 = "rg01"
  namespace                                            = "${module.random_name.name}"
  location                                             = "${local.location}"
}

# define virtual network that everything lives in
module "vnet01" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/azure_virtual_network//?ref=v2.0.0-beta2"
  name                                                 = "vnet01"
  namespace                                            = "${module.random_name.name}"
  location                                             = "${local.location}"
  resource_group_name                                  = "${module.rg01.name}"
  address_space                                        = ["10.0.0.0/16"]
}

module "subnet01" {
  # This module also creates an NSG with a bunch of required, but annoying rules
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/azure_virtual_network//modules/subnet?ref=v2.0.0-beta2"
  name                                                 = "subnet01"
  namespace                                            = "${module.random_name.name}"
  virtual_network_name                                 = "${module.vnet01.name}"
  resource_group_name                                  = "${module.rg01.name}"
  network_security_group_name                          = "subnet01-nsg01"
  network_security_group_location                      = "${local.location}"
  address_prefix                                       = "10.0.2.0/24"
  # this is how the subnet knows to use the route that sends traffic to the firewall
  route_table_id                                       = "${azurerm_route_table.route_table01.id}"
}

# so we have to add a few rules back in to get things to work
resource "azurerm_network_security_rule" "proxy_access" {
  name                                                 = "proxy_access"
  description                                          = "Allow VNET to Proxy"
  resource_group_name                                  = "${module.rg01.name}"
  network_security_group_name                          = "${module.subnet01.network_security_group_name}"
  priority                                             = "100"
  access                                               = "Allow"
  direction                                            = "Outbound"
  protocol                                             = "tcp"
  source_address_prefix                                = "VirtualNetwork"
  source_port_range                                    = "*"
  destination_address_prefix                           = "${module.egress_proxy.private_ip_address}"
  destination_port_range                               = "3128"
}

resource "azurerm_route_table" "route_table01" {
  name                                                 = "route_table01"
  resource_group_name                                  = "${module.rg01.name}"
  location                                             = "${local.location}"
}

resource "azurerm_route" "default_route" {
  name                                                 = "route01"
  resource_group_name                                  = "${module.rg01.name}"
  route_table_name                                     = "${azurerm_route_table.route_table01.name}"
  address_prefix                                       = "0.0.0.0/0"
  next_hop_type                                        = "VirtualAppliance"
  next_hop_in_ip_address                               = "${module.egress_proxy.private_ip_address}"
}

module "egress_proxy" {
  source                                               = "../../modules/squid"
  name                                                 = "egressproxy01"
  location                                             = "${local.location}"
  resource_group_name                                  = "${module.rg01.name}"
  virtual_network_name                                 = "${module.vnet01.name}"
  address_prefix                                       = "10.0.1.0/24"
  squid_rules                                          = "${local.squid_rules}"
}

resource "random_string" "hostname" {
  length                                               = 8
  special                                              = false
  upper                                                = false
  number                                               = false
}

resource "random_string" "password" {
  length                                               = 16
  special                                              = true
  override_special                                     = "-_=+;:[]{}"
  min_special                                          = 1
  min_upper                                            = 1
  min_lower                                            = 1
  min_numeric                                          = 1
}

module "nic01" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/azure_virtual_network//modules/network_interface/primary_ip_configuration?ref=v2.0.0-beta2"
  name                                                 = "nic01"
  namespace                                            = "${module.random_name.name}"
  resource_group_name                                  = "${module.rg01.name}"
  location                                             = "${local.location}"
  ip_configuration_name                                = "primary_config"
  ip_configuration_subnet_id                           = "${module.subnet01.id}"
  ip_configuration_private_ip_address_allocation       = "dynamic"
}

resource "azurerm_storage_account" "storageacct01" {
  # name has to be unique, so add random bits at end
  name                                                 = "${module.random_name.name}"
  resource_group_name                                  = "${module.rg01.name}"
  location                                             = "${local.location}"
  account_replication_type                             = "LRS"
  account_tier                                         = "Standard"
  account_kind                                         = "Storage"
  enable_https_traffic_only                            = true
}

resource "azurerm_virtual_machine" "vm01" {
  name                                                 = "vm01"
  location                                             = "${local.location}"
  resource_group_name                                  = "${module.rg01.name}"
  network_interface_ids                                = ["${module.nic01.id}"]
  vm_size                                              = "Standard_B1s"
  delete_os_disk_on_termination                        = true
  delete_data_disks_on_termination                     = true
  storage_image_reference {
    publisher                                          = "Canonical"
    offer                                              = "UbuntuServer"
    sku                                                = "18.04-LTS"
    version                                            = "latest"
  }
  storage_os_disk {
    name                                               = "vm01-disk00"
    caching                                            = "ReadWrite"
    disk_size_gb                                       = "32"
    managed_disk_type                                  = "Standard_LRS"
    create_option                                      = "FromImage"
  }
  os_profile {
    computer_name                                      = "vm01"
    admin_username                                     = "${local.admin_username}"
    admin_password                                     = "${random_string.password.result}"
    custom_data                                        = "${data.template_cloudinit_config.config.rendered}"
  }
  os_profile_linux_config {
    disable_password_authentication                    = false
  }
  boot_diagnostics {
    enabled                                            = true
    storage_uri                                        = "${azurerm_storage_account.storageacct01.primary_blob_endpoint}"
  }
}

################################################################################
#  OUTPUTS
################################################################################

output "resource_group_name" {
  value                                                = "${module.rg01.name}"
}

output "proxy_admin_password" {
  value                                                = "${module.egress_proxy.os_admin_password}"
}

output "proxy_admin_username" {
  value                                                = "${module.egress_proxy.os_admin_username}"
}

output "proxy_private_ip" {
  value                                                = "${module.egress_proxy.private_ip_address}"
}

output "proxy_public_fqdn" {
  value                                                = "${module.egress_proxy.publicip_fqdn}"
}

output "proxy_public_ip" {
  value                                                = "${module.egress_proxy.publicip_ip_address}"
}

output "vm_admin_password" {
  value                                                = "${random_string.password.result}"
}

output "vm_admin_username" {
  value                                                = "${local.admin_username}"
}

output "vm_private_ip" {
  value                                                = "${module.nic01.private_ip_address}"
}
