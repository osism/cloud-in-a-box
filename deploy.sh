#!/usr/bin/env bash

export INTERACTIVE=false

wait_for_container_healthy() {
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1

    until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' $name)" == "healthy" ]]; do
        if (( attempt_num++ == max_attempts )); then
            return 1
        else
            sleep 5
        fi
    done
}

osism apply facts

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
