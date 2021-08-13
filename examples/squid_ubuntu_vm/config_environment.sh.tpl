#!/bin/bash

cat <<'EOM' >>/etc/environment
http_proxy="http://${proxy_ip}:3128/"
https_proxy="http://${proxy_ip}:3128/"
EOM
