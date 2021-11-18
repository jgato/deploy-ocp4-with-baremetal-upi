#! /bin/bash

# basic tools
sudo dnf install -y vim jq wget tar bash-completion bind-util bind-utils

# loadbalancer and pxe

sudo dnf install -y haproxy.x86_64

# http server

sudo dnf install -y httpd
