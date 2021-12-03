#!/usr/bin/env bash

osism apply bootstrap
osism apply homer
osism apply common
osism apply haproxy
osism apply elasticsearch
osism apply kibana
osism apply openvswitch
osism apply ovn
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
osism apply cinder
osism apply neutron
osism apply nova
osism apply panko
osism apply octavia
osism apply designate
osism apply barbican
osism apply kuryr
osism apply zun
osism apply openstackclient
osism apply --environment custom bootstrap-openstack
