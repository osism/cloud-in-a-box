#!/usr/bin/env bash

firstip_address=$(hostname --all-ip-addresses | awk '{print $1}')
first_network_interface=$(ip -br -4 a sh | grep ${firstip_address} | awk '{print $1}')

find /opt/configuration -type f -exec sed -i "s/eno1/${first_network_interface}/g" {} \;
