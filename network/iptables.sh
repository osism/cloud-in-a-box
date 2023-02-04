#!/usr/bin/env bash

if [[ $IFACE == "{{ network_mgmt_interface }}" ]]; then
    iptables -A FORWARD -i {{ network_mgmt_interface }} -j ACCEPT
    iptables -A FORWARD -o {{ network_mgmt_interface }} -j ACCEPT
    iptables -t nat -A POSTROUTING -o {{ network_mgmt_interface }} -j MASQUERADE
fi
