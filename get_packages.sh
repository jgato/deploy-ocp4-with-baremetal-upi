#! /bin/bash

# basic tools
sudo dnf install -y vim jq wget tar bash-completion bind-util bind-utils coreos-installer.x86_64

# loadbalancer and pxe

sudo dnf install -y haproxy.x86_64 tftp.x86_64 tftp-server.x86_64 syslinux-tftpboot

# http server

sudo dnf install -y httpd
