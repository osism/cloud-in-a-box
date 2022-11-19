#!/usr/bin/env bash

export INTERACTIVE=false

wipefs -a /dev/sdb
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

osism apply common
osism apply loadbalancer
osism apply elasticsearch
osism apply kibana
osism apply openvswitch
osism apply ovn
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq
osism apply iscsi

osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder
osism apply designate
osism apply octavia

osism apply grafana
osism apply homer
osism apply openstackclient
osism apply phpmyadmin

osism apply wireguard
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(hostname --all-ip-addresses | awk '{print $1}')/ /home/dragon/wireguard-client.conf
