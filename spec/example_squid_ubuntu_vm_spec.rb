require 'spec_helper'
require "commercial_cloud/test/terraform"
require "commercial_cloud/test/matcher/terraform"

include CommercialCloud::Test

describe 'example_squid_ubuntu_vm' do

  # Setup terraform client
  before(:all) do
    @tf = Terraform.new(
      default_target_dir: "#{__dir__}/fixtures"
    )
  end

  it 'should verify the plan output' do
    hcl = %{
      module "squid_ubuntu_vm" {
        source = "#{__dir__}/../examples/squid_ubuntu_vm"
      }
    }
    plan_out = @tf.plan(hcl: hcl)
    expect(plan_out)
      .to be_terraform_plan
        .to_add(60)
        .to_change(0)
        .to_destroy(0)
        .with_resources({
          "module.squid_ubuntu_vm.module.egress_proxy.azurerm_network_security_rule.proxy_http_out" => {
             "access"                                                             => "Allow",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "80",
             "direction"                                                          => "Outbound",
             "name"                                                               => "proxy_http_out",
             "network_security_group_name"                                        => "${module.egress_fwsubnet.network_security_group_name}",
             "priority"                                                           => "100",
             "protocol"                                                           => "tcp",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "${module.nic01.private_ip_address}",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.azurerm_network_security_rule.proxy_https_out" => {
             "access"                                                             => "Allow",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "443",
             "direction"                                                          => "Outbound",
             "name"                                                               => "proxy_https_out",
             "network_security_group_name"                                        => "${module.egress_fwsubnet.network_security_group_name}",
             "priority"                                                           => "101",
             "protocol"                                                           => "tcp",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "${module.nic01.private_ip_address}",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.azurerm_network_security_rule.proxy_squid_in" => {
             "access"                                                             => "Allow",
             "destination_address_prefix"                                         => "${module.nic01.private_ip_address}",
             "destination_port_range"                                             => "3128",
             "direction"                                                          => "Inbound",
             "name"                                                               => "proxy_squid_in",
             "network_security_group_name"                                        => "${module.egress_fwsubnet.network_security_group_name}",
             "priority"                                                           => "100",
             "protocol"                                                           => "tcp",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "VirtualNetwork",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.azurerm_public_ip.egress_fwip" => {
             "domain_name_label"                                                  => "${length(var.domain_name_label) == 0 ? module.random_hostname.name : var.domain_name_label}",
             "idle_timeout_in_minutes"                                            => "4",
             "ip_version"                                                         => "IPv4",
             "location"                                                           => "centralus",
             "name"                                                               => "${module.ip_namespace.name}",
             "public_ip_address_allocation"                                       => "static",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "sku"                                                                => "Standard"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.azurerm_storage_account.storageacct01" => {
             "account_encryption_source"                                          => "Microsoft.Storage",
             "account_kind"                                                       => "Storage",
             "account_replication_type"                                           => "LRS",
             "account_tier"                                                       => "Standard",
             "enable_blob_encryption"                                             => "true",
             "enable_file_encryption"                                             => "true",
             "enable_https_traffic_only"                                          => "true",
             "location"                                                           => "centralus",
             "name"                                                               => "${module.storage_account_namespace.name}",
             "resource_group_name"                                                => "${var.resource_group_name}"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.azurerm_virtual_machine.proxyvm" => {
             "boot_diagnostics.#"                                                 => "1",
             "boot_diagnostics.0.enabled"                                         => "true",
             "boot_diagnostics.0.storage_uri"                                     => "${length(var.console_storage_uri) == 0 ? azurerm_storage_account.storageacct01.primary_blob_endpoint : var.console_storage_uri}",
             "delete_data_disks_on_termination"                                   => "true",
             "delete_os_disk_on_termination"                                      => "true",
             "location"                                                           => "centralus",
             "name"                                                               => "${module.vm_namespace.name}",
             "os_profile.#"                                                       => "1",
             "os_profile.~1794861908.admin_password"                              => /<sensitive>/,
             "os_profile.~1794861908.admin_username"                              => "osadmin",
             "os_profile.~1794861908.computer_name"                               => "egressproxy01vm",
             "os_profile_linux_config.#"                                          => "1",
             "os_profile_linux_config.2972667452.disable_password_authentication" => "false",
             "os_profile_linux_config.2972667452.ssh_keys.#"                      => "0",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "storage_image_reference.#"                                          => "1",
             "storage_image_reference.1211973898.id"                              => "",
             "storage_image_reference.1211973898.offer"                           => "UbuntuServer",
             "storage_image_reference.1211973898.publisher"                       => "Canonical",
             "storage_image_reference.1211973898.sku"                             => "18.04-LTS",
             "storage_image_reference.1211973898.version"                         => "latest",
             "storage_os_disk.#"                                                  => "1",
             "storage_os_disk.0.caching"                                          => "ReadWrite",
             "storage_os_disk.0.create_option"                                    => "FromImage",
             "storage_os_disk.0.disk_size_gb"                                     => "32",
             "storage_os_disk.0.managed_disk_type"                                => "Standard_LRS",
             "storage_os_disk.0.name"                                             => "egressproxy01vm-disk00",
             "storage_os_disk.0.write_accelerator_enabled"                        => "false",
             "vm_size"                                                            => "Standard_A1_v2"
          },
          "module.squid_ubuntu_vm.module.nic01.azurerm_network_interface.network_interface" => {
             "enable_accelerated_networking"                                      => "false",
             "enable_ip_forwarding"                                               => "false",
             "internal_dns_name_label"                                            => "${local.internal_dns_name_label}",
             "ip_configuration.#"                                                 => "1",
             "ip_configuration.0.name"                                            => "primary_config",
             "ip_configuration.0.primary"                                         => "true",
             "ip_configuration.0.private_ip_address_allocation"                   => "dynamic",
             "ip_configuration.0.subnet_id"                                       => "${var.ip_configuration_subnet_id}",
             "location"                                                           => "centralus",
             "name"                                                               => "${module.namespace.name}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "tags.cc-eac_azure_virtual_network"                                  => "v2.0.0"
          },
          "module.squid_ubuntu_vm.module.rg01.azurerm_resource_group.resource_group" => {
             "location"                                                           => "centralus",
             "name"                                                               => "${module.namespace.name}",
             "tags.cc-eac_azure_resource_group"                                   => "v2.0.0"
          },
          "module.squid_ubuntu_vm.module.subnet01.azurerm_subnet.subnet" => {
             "address_prefix"                                                     => "10.0.2.0/24",
             "name"                                                               => "${module.namespace.name}",
             "network_security_group_id"                                          => "${module.network_security_group.id}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "route_table_id"                                                     => "${var.route_table_id}",
             "virtual_network_name"                                               => "${var.virtual_network_name}"
          },
          "module.squid_ubuntu_vm.module.vnet01.azurerm_virtual_network.virtual_network" => {
             "address_space.#"                                                    => "1",
             "address_space.0"                                                    => "10.0.0.0/16",
             "location"                                                           => "centralus",
             "name"                                                               => "${module.namespace.name}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "tags.cc-eac_azure_virtual_network"                                  => "v2.0.0"
     
          },
          "module.squid_ubuntu_vm.module.egress_proxy.module.egress_fwsubnet.azurerm_subnet.subnet" => {
             "address_prefix"                                                     => "10.0.1.0/24",
             "name"                                                               => "${module.namespace.name}",
             "network_security_group_id"                                          => "${module.network_security_group.id}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "virtual_network_name"                                               => "${var.virtual_network_name}"
          },
     
          "module.squid_ubuntu_vm.module.egress_proxy.module.nic01.azurerm_network_interface.network_interface" => {
             "enable_accelerated_networking"                                      => "false",
             "enable_ip_forwarding"                                               => "false",
             "internal_dns_name_label"                                            => "${local.internal_dns_name_label}",
             "ip_configuration.#"                                                 => "1",
             "ip_configuration.0.name"                                            => "primary_config",
             "ip_configuration.0.primary"                                         => "true",
             "ip_configuration.0.private_ip_address"                              => "10.0.1.4",
             "ip_configuration.0.private_ip_address_allocation"                   => "static",
             "ip_configuration.0.public_ip_address_id"                            => "${var.ip_configuration_public_ip_address_id}",
             "ip_configuration.0.subnet_id"                                       => "${var.ip_configuration_subnet_id}",
             "location"                                                           => "centralus",
             "name"                                                               => "${module.namespace.name}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "tags.cc-eac_azure_virtual_network"                                  => "v2.0.0"
          },
          "module.squid_ubuntu_vm.module.subnet01.module.network_security_group.azurerm_network_security_group.network_security_group" => {
             "location"                                                           => "centralus",
             "name"                                                               => "${module.namespace.name}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "tags.cc-eac_azure_virtual_network"                                  => "v2.0.0"
          },
          "module.squid_ubuntu_vm.module.subnet01.module.network_security_group.azurerm_network_security_rule.allow_inbound_azure_load_balancer" => {
             "access"                                                             => "Allow",
             "description"                                                        => "Allow inbound access from Azure Load Balancer.",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "*",
             "direction"                                                          => "Inbound",
             "name"                                                               => "AllowInboundAzureLoadBalancer",
             "network_security_group_name"                                        => "${azurerm_network_security_group.network_security_group.name}",
             "priority"                                                           => "1000",
             "protocol"                                                           => "*",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "AzureLoadBalancer",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.subnet01.module.network_security_group.azurerm_network_security_rule.deny_all_inbound" => {
             "access"                                                             => "Deny",
             "description"                                                        => "Denies all inbound traffic.",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "*",
             "direction"                                                          => "Inbound",
             "name"                                                               => "DenyAllInboundTraffic",
             "network_security_group_name"                                        => "${azurerm_network_security_group.network_security_group.name}",
             "priority"                                                           => "4095",
             "protocol"                                                           => "*",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "*",
             "source_port_range"                                                  => "*"
          },
     
          "module.squid_ubuntu_vm.module.subnet01.module.network_security_group.azurerm_network_security_rule.deny_all_outbound" => {
             "access"                                                             => "Deny",
             "description"                                                        => "Denies all outbound traffic.",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "*",
             "direction"                                                          => "Outbound",
             "name"                                                               => "DenyAllOutboundTraffic",
             "network_security_group_name"                                        => "${azurerm_network_security_group.network_security_group.name}",
             "priority"                                                           => "4096",
             "protocol"                                                           => "*",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "*",
             "source_port_range"                                                  => "*"
     
          },
          "module.squid_ubuntu_vm.module.egress_proxy.module.egress_fwsubnet.module.network_security_group.azurerm_network_security_group.network_security_group" => {
             "location"                                                           => "centralus",
             "name"                                                               => "${module.namespace.name}",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "tags.cc-eac_azure_virtual_network"                                  => "v2.0.0"
     
          },
          "module.squid_ubuntu_vm.module.egress_proxy.module.egress_fwsubnet.module.network_security_group.azurerm_network_security_rule.allow_inbound_azure_load_balancer" => {
             "access"                                                             => "Allow",
             "description"                                                        => "Allow inbound access from Azure Load Balancer.",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "*",
             "direction"                                                          => "Inbound",
             "name"                                                               => "AllowInboundAzureLoadBalancer",
             "network_security_group_name"                                        => "${azurerm_network_security_group.network_security_group.name}",
             "priority"                                                           => "1000",
             "protocol"                                                           => "*",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "AzureLoadBalancer",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.module.egress_fwsubnet.module.network_security_group.azurerm_network_security_rule.deny_all_inbound" => {
             "access"                                                             => "Deny",
             "description"                                                        => "Denies all inbound traffic.",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "*",
             "direction"                                                          => "Inbound",
             "name"                                                               => "DenyAllInboundTraffic",
             "network_security_group_name"                                        => "${azurerm_network_security_group.network_security_group.name}",
             "priority"                                                           => "4095",
             "protocol"                                                           => "*",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "*",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.egress_proxy.module.egress_fwsubnet.module.network_security_group.azurerm_network_security_rule.deny_all_outbound" => {
             "access"                                                             => "Deny",
             "description"                                                        => "Denies all outbound traffic.",
             "destination_address_prefix"                                         => "*",
             "destination_port_range"                                             => "*",
             "direction"                                                          => "Outbound",
             "name"                                                               => "DenyAllOutboundTraffic",
             "network_security_group_name"                                        => "${azurerm_network_security_group.network_security_group.name}",
             "priority"                                                           => "4096",
             "protocol"                                                           => "*",
             "resource_group_name"                                                => "${var.resource_group_name}",
             "source_address_prefix"                                              => "*",
             "source_port_range"                                                  => "*"
          },
          "module.squid_ubuntu_vm.module.subnet01.module.network_security_group.module.nsg_diagnostic_log.null_resource.diagnostic_log" => {
             "id"                                                                 => /<computed>/,
             "triggers.%"                                                         => /<computed>/
          },
          "module.squid_ubuntu_vm.module.egress_proxy.module.egress_fwsubnet.module.network_security_group.module.nsg_diagnostic_log.null_resource.diagnostic_log" => {
             "id"                                                                 => /<computed>/,
             "triggers.%"                                                         => /<computed>/
          }
        })
  end
end
