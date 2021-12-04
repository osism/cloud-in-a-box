#!/usr/bin/env bash

osism apply bootstrap
osism apply homer

# NOTE: comment the following lines if Ceph is used
sudo pvcreate /dev/sdb
sudo vgcreate cinder-volumes /dev/sdb
osism apply iscsi

osism apply common
osism apply haproxy
osism apply elasticsearch
osism apply kibana
osism apply openvswitch
osism apply memcached
osism apply redis
osism apply etcd
osism apply mariadb
osism apply phpmyadmin
osism apply rabbitmq
osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder
osism apply ironic

osism apply openstackclient
osism apply --environment custom bootstrap-openstack
