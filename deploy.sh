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
osism apply netdata
osism apply openstackclient
osism apply phpmyadmin

osism apply wireguard
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(hostname --all-ip-addresses | awk '{print $1}')/ /home/dragon/wireguard-client.conf

osism apply --environment openstack bootstrap

# osism manage images is only available since 4.3.0. To enable the
# testbed to be used with < 4.3.0, here is this check.
MANAGER_VERSION=$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' osism-ansible)
if [[ $MANAGER_VERSION == "4.0.0" || $MANAGER_VERSION == "4.1.0" || $MANAGER_VERSION == "4.2.0" ]]; then
    osism apply --environment openstack bootstrap-images
else
    osism manage images --cloud admin --filter Cirros
    osism manage images --cloud admin --name "Ubuntu 22.04 Minimal"
fi
