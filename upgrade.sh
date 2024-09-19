#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "set +x; add_status 'error' 'UPGRADE FAILED'" TERM INT EXIT

set -x
set -e

export INTERACTIVE=false
source /etc/cloud-in-a-box.env

# The normal way of updating the configuration repository (osism apply configuration)
# is not used as we have made manual changes in the configuration repository
# on the Cloud in a Box. For example, for the primary network card.
pushd /opt/configuration
git pull
popd

osism update manager
osism update docker
osism apply traefik

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply netbox
fi

osism reconciler sync
osism apply facts

# Minified version of the Cloud in a Box in which only Kubernetes is upgraded.
if [[ $CLOUD_IN_A_BOX_TYPE == "kubernetes" ]]; then
    # Upgrade kubernetes
    osism apply kubernetes

    exit 0
fi

# Pull container images
osism apply -e custom pull-container-images

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

# upload octavia amphora image
 osism manage image octavia

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply -a upgrade skyline
    osism apply -a upgrade barbican
    osism apply -a upgrade prometheus
    osism apply -a upgrade grafana
    osism apply phpmyadmin
    osism apply homer
    osism apply netdata
fi

osism apply openstackclient

# Upgrade kubernetes
osism apply kubernetes

# Upgrade clusterapi
osism apply clusterapi

# In the Cloud in a Box, the service was only added with OSISM 7.0.0. It is therefore necessary
# to check in advance whether the service is already available. If not, a deployment must be
# carried out instead of an upgrade.
if [[ -z $(openstack --os-cloud admin service list -f value -c Name | grep magnum) ]]; then
    osism apply copy-kubeconfig
    osism apply magnum
else
    osism apply -a upgrade magnum
fi

osism apply cleanup-docker-images -e ireallymeanit=yes
