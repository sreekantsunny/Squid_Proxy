## How to update Squid rules:

Because local.squid_rules is passed in via cloud-init and Terraform has no visibility into the VM itself (and doesn't track cloud-init values), you will have to manually 'taint' the proxy if/when you want to update the squid rules/configuration.  To do so, follow these steps:

1. Update rules file in main.tf

2. Instruct Terraform to Taint the proxy virtual machine (so that it will get rebuilt):

```terraform taint -module=egress_proxy azurerm_virtual_machine.proxyvm```

3. Apply changes

```terraform apply```


## How to check squid logs:

Logs are rotated 


1. Open the Serial Console for the "egressproxy01vm" virtual machine, and log in using the credentials output by Terraform (proxy_admin_username, proxy_admin_password)

2. Once logged in, type "sudo su -", and then "cd /var/log/squid"

3. There will be 3 files:

```
access.log:  Contains log entries for all client uses (both successful and unsuccessful) of Squid
cache.log:   Contains debug and error messages from Squid
netdb.state: Squid internal Network Measurement Database (you can ignore this file)
```

Typical access.log entries look like this (one for a succss, but cache miss, and another for a denied site):
```
1540352572.748    153 10.0.2.4 TCP_MISS/200 13030 GET http://www.google.com/ - HIER_DIRECT/172.217.3.196 text/html
1540354719.557    286 10.0.2.4 TCP_DENIED/403 3937 GET http://www.optum.com/ - HIER_NONE/- text/html
```
