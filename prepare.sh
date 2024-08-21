#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "set +x; add_status 'error' 'PREPARE FAILED'; sleep 90" TERM INT EXIT

set -x
set -e

default_gateway_interface="$(get_ethernet_interface_of_default_gateway)"
get_default_gateway_settings

find /opt/configuration -type f -exec sed -i "s/eno1/${default_gateway_interface}/g" {} +

echo "PREPARE COMPLETE"
