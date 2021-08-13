#!/bin/bash -x
# 
# Run as root - installs squid proxy
#
APTGET="$$(which apt-get 2>/dev/null)"
YUM="$$(which yum 2>/dev/null)"

if [ -e "$$APTGET" ]; then
  apt-get install -y squid
elif [ -e "$$YUM" ]; then
  echo "NOT SUPPORTED"
  exit 100
else
  echo "Cannot install Squid"
  exit 255
fi

# workaround for cloud-init (or Terraform) messing up order of scripts

if [ -e "/etc/squid/squid-new.conf" ]; then
  cp /etc/squid/squid.conf /etc/squid/squid-orig.conf
  cp /etc/squid/squid-new.conf /etc/squid/squid.conf
  systemctl restart squid
fi
