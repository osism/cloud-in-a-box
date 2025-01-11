#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "set +x; add_status 'error' 'PREPARE FAILED'; sleep 90" TERM INT EXIT

set -x
set -e

default_gateway_interface="$(get_ethernet_interface_of_default_gateway)"
get_default_gateway_settings

find /opt/configuration -type f -exec sed -i "s/eno1/${default_gateway_interface}/g" {} +

default_dns_servers="$(get_default_dns_servers)"
sed -i "s/designate_forwarders_addresses: .*/designate_forwarders_addresses: \"$default_dns_servers\"/" /opt/configuration/environments/kolla/configuration.yml

echo "PREPARE COMPLETE"
