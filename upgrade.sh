#!/usr/bin/env bash


BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

set -x
set -e

export INTERACTIVE=false
source /etc/cloud-in-a-box.env


# The upgrade of Docker must be done on the manager via script because the docker service is restarted.
# In the future, an "osism update docker" wrapper similar to the "osism update manager" wrapper
# will be available.

pushd /opt/configuration/environments/manager
./run.sh docker
popd

osism update manager

osism apply traefik

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply netbox
fi

osism reconciler sync
osism apply facts

# pull container images in background
bash $BASE_DIR/pull.sh

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
osism apply -a upgrade skyline
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

CAPI_VERSION="v1.5.1"
CAPO_VERSION="v0.8.0"

export KUBECONFIG=/home/dragon/.kube/config
sudo curl -Lo /usr/local/bin/clusterctl https://github.com/kubernetes-sigs/cluster-api/releases/download/${CAPI_VERSION}/clusterctl-linux-amd64
sudo chmod +x /usr/local/bin/clusterctl
export EXP_CLUSTER_RESOURCE_SET=true
export CLUSTER_TOPOLOGY=true
clusterctl upgrade apply \
  --core cluster-api:${CAPI_VERSION} \
  --bootstrap kubeadm:${CAPI_VERSION} \
  --control-plane kubeadm:${CAPI_VERSION} \
  --infrastructure openstack:${CAPO_VERSION}
