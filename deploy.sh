#!/usr/bin/env bash

wipefs -a /dev/sdb
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb

osism apply common
osism apply iscsi
osism apply loadbalancer
osism apply openvswitch
osism apply ovn
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq
osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder

osism apply openstackclient
