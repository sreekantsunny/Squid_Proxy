#!/bin/bash

mkdir -p /etc/squid

cat <<'EOM' >/etc/squid/squid-new.conf

# localnet ACL includes all source IPs which may access this proxy
acl localnet src 10.0.0.0/8     # RFC1918 possible internal network
acl localnet src 172.16.0.0/12  # RFC1918 possible internal network
acl localnet src 192.168.0.0/16 # RFC1918 possible internal network

# these ports should match network security group outbound access
acl Safe_ports port 80          # http
acl Safe_ports port 443         # https
acl CONNECT method CONNECT
acl SSL_ports port 443
http_access deny CONNECT !SSL_ports
http_access deny !Safe_ports
http_access allow localhost manager
http_access deny manager
http_access deny to_localhost
http_access allow localhost

# deny any connection to the Azure special services IPs
acl azure_internals dst 169.254.169.254  # used for metadata (similar to AWS)
acl azure_internals dst 168.63.129.16    # used for communicating between VM and Azure (and shouldn't be proxied)
http_access deny azure_internals

################################################################################

${squid_rules}

################################################################################

http_access deny all

http_port 3128
coredump_dir /var/spool/squid
refresh_pattern ^ftp:           1440    20%     10080
refresh_pattern ^gopher:        1440    0%      1440
refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
refresh_pattern (Release|Packages(.gz)*)$      0       20%     2880
refresh_pattern .                 0       20%     4320

EOM

# workaround for cloud-init (or Terraform) messing up order of scripts
systemctl -n0 -q status squid >/dev/null 2>&1
ERR=$?
if [ $ERR -eq 0 ]; then
  systemctl restart squid
fi
