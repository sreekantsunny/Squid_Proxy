# azure egress proxy

## Overview
This module is designed to hold multiple solutions (each with pros/cons) that can be used with nearly identical configuration.  Currently Squid Cache is the only fully-implemented solution, but an Azure Firewall solution is also in planning.

### Squid `[/modules/squid]`

Creates the following reources:
 - public static IP for proxy (and optional dns entry)
 - VM with Squid Cache running on port 3128
 - subnet in given virtual network
 - NSGs for inbound/outbound access to subnet
 - storage account for VM's serial console, if none specified
 - VM monitoring extension for the squid proxy VM (only if workspace_id is set)

## Terrform Modules

### Squid Inputs
| Property | Description | Default |
| --- | --- | --- |
| name | Name (prefix) of egress proxy resources | egress_proxy |
| resource_group_name" | Resource group name in which to crete egress proxy resources | "" |
| location | Location where egress proxy resources will be created | centralus |
| virtual_network_name | Virtual network in which a subnet will be built for Squid Cache VM | |
| address_prefix | CIDR to use for subnet built (in the virtual_network_name) for the egress proxy | |
| proxy_private_ip_address | IP to use for subnet built (in the virtual_network_name) for the egress proxy.  If not set/blank, it will be the fourth IP within the address_prefix CIDR range (Azure internals use the first 3 addresses).  For example, if address_profile was 10.0.3.0/24, 10.0.3.4 would be chosen as the proxy_private_ip_address. | "" |
| proxy_vm_size | Virtual Machine size used for Squid Cache | Standard_A1_v2 |
| console_storage_uri | Primary_blob_endpoint to use for proxy VM's serial console.  If not specified, a storage account for the VM will be created. | "" |
| domain_name_label | If specified, a DNS entry for the proxy will be created using this name.  If not specified, a random name will be chosen for the DNS entry. | "" |
| admin_username | Proxy OS username, which can log in and sudo from the serial console | osadmin |
| admin_password | If not specified/blank, a random password will be created | "" |
| squid_rules | List (ordered) of rules to insert into squid.conf (each string in list will appear in file as-is).  Should include an ACL line, as well as an http_access line (allowing 'localnet' to go to somewhere). For example, to allow access to \*.google.com, set this to [ \"acl google dstdomain .google.com\", \"http_access allow localnet google\" ] | [] |
| tags | Set of tags used for this resource | {} |
| global_tags | Set of tags used for all resoruces | {} |
| workspace_id | Log analytics workspace ID (for getting squid logs into Log Analytics).  If defined, this installs the VM Monitoring Extension and connects it to this workspace. Also requires workspace_key if set.| "" |
| workspace_key | Log analytics workspace key (used only when workspace_id is set) | "" |

### Squid Outputs
| Output | Description |
| --- | --- |
| name | Name (prefix) of egress proxy resources |
| ip_configuration | This is a synthesized map, to match what is produced by azurerm_firewall.  Only contains the "private_ip_address" key, currently |
| subnet_id | egress proxy subnet ID |
| subnet_name | egress proxy subnet name |
| subnet_address_prefix | egress proxy subnet prefix (CIDR) |
| subnet_ip_configurations | egress proxy subnet ip configuration |
| publicip_id | ID of public IP of the egress proxy |
| publicip_fqdn | fully-qualified domain name for publicip_id)
| publicip_ip_address" | public IP address of the egress proxy |
| private_ip_address | private/internal IP address of the egress proxy |
| os_admin_username | egress proxy VM OS admin user |
| os_admin_password | egress proxy VM OS admin password |


## Commonly-used Squid Rules

### Ubuntu updates
```
[
  "acl allowed_domains dstdomain azure.archive.ubuntu.com",
  "acl allowed_domains dstdomain security.ubuntu.com",
  "http_access allow localnet allowed_domains"
]
```

### CentOS updates (assuming you're using OpenLogic's images)
```
[
  "acl allowed_domains dstdomain olcentgbl.trafficmananager.net",
  "http_access allow localnet allowed_domains"
]
```

### RedHat updates
```
[
  "acl allowed_domains dstdomain rhui-1.microsoft.com",
  "acl allowed_domains dstdomain rhui-2.microsoft.com",
  "acl allowed_domains dstdomain rhui-3.microsoft.com",
  "http_access allow localnet allowed_domains"
]
```

### Windows updates
```
[
  "acl allowed_domains dstdomain windowsupdate.microsoft.com",
  "acl allowed_domains dstdomain .windowsupdate.microsoft.com",
  "acl allowed_domains dstdomain .update.microsoft.com",
  "acl allowed_domains dstdomain .windowsupdate.com",
  "acl allowed_domains dstdomain download.windowsupdate.com",
  "acl allowed_domains dstdomain download.microsoft.com
  "acl allowed_domains dstdomain .download.windowsupdate.com",
  "acl allowed_domains dstdomain test.stats.update.microsoft.com",
  "acl allowed_domains dstdomain ntservicepack.microsoft.com"
  "http_access allow localnet allowed_domains"
]
```

### UHG/UHC/Optum networks (just an example)
```
[
  "acl allowed_domains dstdomain .optum.com"
  "acl allowed_domains dstdomain .uhg.com"
  "acl allowed_domains dstdomain .uhc.com"
  "http_access allow localnet allowed_domains"
]
