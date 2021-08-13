variable "name" {
  description = "Name (prefix) of egress proxy resources"
  default = "egress_proxy"
}

variable "resource_group_name" {
  description = "Resource group name in which to crete egress proxy resources"
  description = ""
}

variable "namespace" {
  description = "Name space to make the instance unique (normally not used)"
  default = ""
}

variable "location" {
  description = "Location where egress proxy resources will be created"
  default = "centralus"
}

variable "virtual_network_name" {
  description = "Virtual network in which a subnet will be built for Squid Cache VM"
}

variable "address_prefix" {
  description = "CIDR to use for subnet built (in the virtual_network_name) for the egress proxy"
}

variable "proxy_private_ip_address" {
  description = "IP to use for subnet built (in the virtual_network_name) for the egress proxy.  If not set/blank, it will be the fourth IP within the address_prefix CIDR range (Azure internals use the first 3 addresses).  For example, if address_profile was 10.0.3.0/24, 10.0.3.4 would be chosen as the proxy_private_ip_address."
  default = ""
}

variable "proxy_vm_size" {
  description = "Virtual Machine size used for Squid Cache"
  default = "Standard_A1_v2"
}

variable "console_storage_uri" {
  description = "Primary_blob_endpoint to use for proxy VM's serial console.  If not specified, a storage account for the VM will be created."
  default = ""
}

variable "domain_name_label" {
  description = "If specified, a DNS entry for the proxy will be created using this name.  If not specified, a random name will be chosen for the DNS entry."
  default = ""
}

variable "admin_username" {
  description = "Proxy OS username, which can log in and sudo from the serial console"
  default = "osadmin"
}

variable "admin_password" {
  description = "If not specified/blank, a random password will be created"
  default = ""
}

variable "squid_rules" {
  description = "Ordered list of rules to insert into squid.conf (each string in list will appear in file as-is).  Should include an ACL line, as well as an http_access line (allowing 'localnet' to go to somewhere). For example, to allow access to *.google.com, set this to [ \"acl google dstdomain .google.com\", \"http_access allow localnet google\" ]"
  type = "list"
  default  = []
}

variable "tags" {
  description = "Set of tags used for this resource"
  default = {}
}

variable "global_tags" {
  description = "Set of tags used for all resoruces"
  default = {}
}

variable "workspace_id" {
  type = "string"
  default = ""
}

variable "workspace_key" {
  type = "string"
  default = ""
}
