#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false
source /etc/cloud-in-a-box.env

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

# The upgrade of Docker must be done on the manager via script because the docker service is restarted.
# In the future, an "osism update docker" wrapper similar to the "osism update manager" wrapper
# will be available.

pushd /opt/configuration/environments/manager
./run.sh docker
popd

osism-update-manager

osism apply traefik

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply netbox
fi

osism reconciler sync
osism apply facts

osism apply -a upgrade common
osism apply -a upgrade loadbalancer

# OpenSearch is only required on the sandbox type. On the edge type,
# the logs will be delivered to a central location in the future.
if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply -a upgrade opensearch
fi

osism apply -a upgrade openvswitch
osism apply -a upgrade ovn
osism apply -a upgrade memcached
osism apply -a upgrade redis
osism apply -a upgrade mariadb
osism apply -a upgrade rabbitmq

# TASK [fail when less than three monitors] **************************************
# fatal: [manager.systems.in-a-box.cloud]: FAILED! => {"changed": false, "msg": "Upgrade
# of cluster with less than three monitors is not supported."}
# osism apply ceph-rolling_update -e ireallymeanit=yes
# osism apply cephclient

osism apply -a upgrade keystone
osism apply -a upgrade horizon
osism apply -a upgrade placement
osism apply -a upgrade glance
osism apply -a upgrade neutron
osism apply -a upgrade nova
osism apply -a upgrade cinder
osism apply -a upgrade designate
osism apply -a upgrade octavia

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply -a upgrade barbican
    osism apply -a upgrade grafana
    osism apply phpmyadmin
    osism apply homer
fi

osism apply netdata
osism apply openstackclient
