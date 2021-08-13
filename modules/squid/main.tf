locals {
  version_tag = {
    "cc-eac_azure_egress_proxy"                        = "v2.0.0"
  }
}

data "template_file" "install_squid" {
  template                                             = "${file("${path.module}/scripts/install_squid.sh.tpl")}"
  vars = {
    fqdn                                               = "${azurerm_public_ip.egress_fwip.fqdn}"
  }
}

data "template_file" "squid_rules" {
  template                                             = "${file("${path.module}/scripts/squid_rule.tpl")}"
  count                                                = "${length(var.squid_rules)}"
  vars = {
    rule                                               = "${var.squid_rules[count.index]}"
  }
}

data "template_file" "config_squid" {
  template                                             = "${file("${path.module}/scripts/config_squid.sh.tpl")}"
  vars = {
    squid_rules                                        = "${join("", data.template_file.squid_rules.*.rendered)}"
  }
}

data "template_cloudinit_config" "config" {
  # cloudinit has a limit of 16kb (after gzip'd)
  gzip                                                 = true
  base64_encode                                        = true
  part {
    filename                                           = "install_squid.sh"
    content_type                                       = "text/x-shellscript"
    content                                            = "${data.template_file.install_squid.rendered}"
  }
  part {
    filename                                           = "config_squid.sh"
    content_type                                       = "text/x-shellscript"
    content                                            = "${data.template_file.config_squid.rendered}"
  }
}

module "random_hostname" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/terraform_common//terraform_module/random_name?ref=v1.2.1"
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

module "egress_fwsubnet" {
  # This module also creates an NSG with a bunch of required, but annoying rules
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/azure_virtual_network//modules/subnet?ref=v2.0.0-beta2"
  name                                                 = "egress_fwsubnet"
  namespace                                            = "${var.namespace}"
  virtual_network_name                                 = "${var.virtual_network_name}"
  resource_group_name                                  = "${var.resource_group_name}"
  network_security_group_name                          = "egress_fwsubnet-nsg01"
  network_security_group_location                      = "${var.location}"
  address_prefix                                       = "${var.address_prefix}"
}

resource "azurerm_network_security_rule" "proxy_http_out" {
  name                                                 = "proxy_http_out"
  description                                          = "Allow Proxy to Internet (http)"
  resource_group_name                                  = "${var.resource_group_name}"
  network_security_group_name                          = "${module.egress_fwsubnet.network_security_group_name}"
  priority                                             = "100"
  access                                               = "Allow"
  direction                                            = "Outbound"
  protocol                                             = "tcp"
  source_address_prefix                                = "${module.nic01.private_ip_address}"
  source_port_range                                    = "*"
  destination_address_prefix                           = "*"
  destination_port_range                               = "80"
}

resource "azurerm_network_security_rule" "proxy_https_out" {
  name                                                 = "proxy_https_out"
  description                                          = "Allow Proxy to Internet (https)"
  resource_group_name                                  = "${var.resource_group_name}"
  network_security_group_name                          = "${module.egress_fwsubnet.network_security_group_name}"
  priority                                             = "101"
  access                                               = "Allow"
  direction                                            = "Outbound"
  protocol                                             = "tcp"
  source_address_prefix                                = "${module.nic01.private_ip_address}"
  source_port_range                                    = "*"
  destination_address_prefix                           = "*"
  destination_port_range                               = "443"
}

resource "azurerm_network_security_rule" "proxy_squid_in" {
  name                                                 = "proxy_squid_in"
  description                                          = "Allow VNET to Proxy (3128)"
  resource_group_name                                  = "${var.resource_group_name}"
  network_security_group_name                          = "${module.egress_fwsubnet.network_security_group_name}"
  priority                                             = "100"
  access                                               = "Allow"
  direction                                            = "Inbound"
  protocol                                             = "tcp"
  source_address_prefix                                = "VirtualNetwork"
  source_port_range                                    = "*"
  destination_address_prefix                           = "${module.nic01.private_ip_address}"
  destination_port_range                               = "3128"
}

module "ip_namespace" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/terraform_common//terraform_module/namespace?ref=v1.2.1"
  name                                                 = "egress_fwip"
  namespace                                            = "${var.namespace}"
  name_format                                          = "%s-%s"
}

resource "azurerm_public_ip" "egress_fwip" {
  name                                                 = "${module.ip_namespace.name}"
  location                                             = "${var.location}"
  resource_group_name                                  = "${var.resource_group_name}"
  public_ip_address_allocation                         = "Static"
  sku                                                  = "Standard"
  domain_name_label                                    = "${length(var.domain_name_label) == 0 ? module.random_hostname.name : var.domain_name_label}"
  tags                                                 = "${var.global_tags}"
}

module "nic01" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/azure_virtual_network//modules/network_interface/primary_ip_configuration?ref=v2.0.0-beta2"
  name                                                 = "${var.name}vm-nic"
  namespace                                            = "${var.namespace}"
  resource_group_name                                  = "${var.resource_group_name}"
  location                                             = "${var.location}"
  ip_configuration_name                                = "primary_config"
  ip_configuration_subnet_id                           = "${module.egress_fwsubnet.id}"
  ip_configuration_private_ip_address_allocation       = "static"
  ip_configuration_private_ip_address                  = "${length(var.proxy_private_ip_address) == 0 ? cidrhost(var.address_prefix, 4) : var.proxy_private_ip_address}"
  ip_configuration_public_ip_address_id                = "${azurerm_public_ip.egress_fwip.id}"
  tags                                                 = "${var.global_tags}"
}

module "storage_account_namespace" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/terraform_common//terraform_module/namespace?ref=v1.2.1"
  name                                                 = "${var.name}${module.random_hostname.name}"
  namespace                                            = "${var.namespace}"
  name_format                                          = "%s%s"
}

resource "azurerm_storage_account" "storageacct01" {
  count                                                = "${length(var.console_storage_uri) == 0 ? 1 : 0}"
  # name has to be unique, so add random bits at end
  name                                                 = "${module.storage_account_namespace.name}"
  resource_group_name                                  = "${var.resource_group_name}"
  location                                             = "${var.location}"
  account_replication_type                             = "LRS"
  account_tier                                         = "Standard"
  account_kind                                         = "Storage"
  enable_https_traffic_only                            = true
  tags                                                 = "${var.global_tags}"
}

module "vm_namespace" {
  source                                               = "git::https://github.optum.com/CommercialCloud-EAC/terraform_common//terraform_module/namespace?ref=v1.2.1"
  name                                                 = "${var.name}vm"
  namespace                                            = "${var.namespace}"
  name_format                                          = "%s-%s"
}

resource "azurerm_virtual_machine" "proxyvm" {
  name                                                 = "${module.vm_namespace.name}"
  location                                             = "${var.location}"
  resource_group_name                                  = "${var.resource_group_name}"
  network_interface_ids                                = ["${module.nic01.id}"]
  vm_size                                              = "${var.proxy_vm_size}"
#  tags                                                 = "${var.global_tags}"
  delete_os_disk_on_termination                        = true
  delete_data_disks_on_termination                     = true
  storage_image_reference {
    publisher                                          = "Canonical"
    offer                                              = "UbuntuServer"
    sku                                                = "18.04-LTS"
    version                                            = "latest"
  }
  storage_os_disk {
    name                                               = "${var.name}vm-disk00"
    caching                                            = "ReadWrite"
    disk_size_gb                                       = "32"
    managed_disk_type                                  = "Standard_LRS"
    create_option                                      = "FromImage"
  }
  os_profile {
    computer_name                                      = "${var.name}vm"
    admin_username                                     = "${var.admin_username}"
    admin_password                                     = "${length(var.admin_password) == 0 ? random_string.password.result : var.admin_password}"
    custom_data                                        = "${data.template_cloudinit_config.config.rendered}"
  }
  os_profile_linux_config {
    disable_password_authentication                    = false
  }
  boot_diagnostics {
    enabled                                            = true
    storage_uri                                        = "${length(var.console_storage_uri) == 0 ? azurerm_storage_account.storageacct01.primary_blob_endpoint : var.console_storage_uri}"
  }
  tags                                                 = "${merge(local.version_tag,var.global_tags)}"
}

# installs monitoring extension if workspace_id is defined
resource "azurerm_virtual_machine_extension" "vmext01" {
  count                                                = "${length(var.workspace_id) == 0 ? 0 : 1}"
  name                                                 = "OmsExtension"
  location                                             = "${var.location}"
  resource_group_name                                  = "${var.resource_group_name}"
  virtual_machine_name                                 = "${azurerm_virtual_machine.proxyvm.name}"
  publisher                                            = "Microsoft.EnterpriseCloud.Monitoring"
  type                                                 = "OmsAgentForLinux"
  type_handler_version                                 = "1.7"
  #auto_upgrade_minor_version                           = false

  settings = <<-BASE_SETTINGS
    {
       "workspaceId" : "${var.workspace_id}"
    }
  BASE_SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
       "workspaceKey" : "${var.workspace_key}"
    }
  PROTECTED_SETTINGS

}
