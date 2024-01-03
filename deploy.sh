#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "add_status 'error' 'DEPLOY FAILED'" TERM INT EXIT
set -x
set -e

export INTERACTIVE=false

if [[ -e /etc/cloud-in-a-box.env ]]; then
    source /etc/cloud-in-a-box.env
else
    CLOUD_IN_A_BOX_TYPE=${1:-sandbox}
    echo "CLOUD_IN_A_BOX_TYPE=$CLOUD_IN_A_BOX_TYPE" | sudo tee /etc/cloud-in-a-box.env
fi

osism apply facts

# pull container images in background
bash $BASE_DIR/pull.sh

osism apply common
osism apply loadbalancer

# OpenSearch is only required on the sandbox type. On the edge type,
# the logs will be delivered to a central location in the future.
if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply opensearch
fi

osism apply openvswitch
osism apply ovn
osism apply memcached
osism apply redis
osism apply mariadb
osism apply rabbitmq

# Create LVs for Ceph since that is currently not possible with Curtin
# with percentages. The VG osd-vg itself is already created by Curtin.
if [[ ! -e /dev/osd-vg/osd-1 ]]; then
    osism apply --environment custom create-logical-volumes
fi

osism reconciler sync

osism apply ceph -e enable_ceph_mds=true -e enable_ceph_rgw=true
osism apply copy-ceph-keys
osism apply cephclient
osism apply ceph-bootstrap-dashboard

osism apply keystone
osism apply horizon
osism apply skyline
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder
osism apply designate
osism apply octavia

osism apply kolla-ceph-rgw

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply barbican
    osism apply prometheus
    osism apply grafana
    osism apply phpmyadmin
    osism apply homer
fi

osism apply netdata
osism apply openstackclient

# Deploy wireguard service
osism apply wireguard

# Apply cloud in a box specific workarounds
osism apply --environment custom workarounds

# Bootstrap the openstack environment
osism apply --environment openstack bootstrap-$CLOUD_IN_A_BOX_TYPE

# Upload machine images
osism manage images --cloud admin --filter Cirros
osism manage images --cloud admin --filter "Ubuntu 22.04 Minimal"

# Create machine types
osism manage flavors

# Create test project (without a server and attached volume)
osism apply --environment openstack test --skip-tags test-server,test-volume

# Deploy kubernetes
osism apply k3s

CAPI_VERSION="v1.5.1"
CAPO_VERSION="v0.8.0"

# NOTE: The following lines will be moved to an osism.services.clusterapi role
export KUBECONFIG=/home/dragon/.kube/config
kubectl label node manager openstack-control-plane=enabled
sudo curl -Lo /usr/local/bin/clusterctl https://github.com/kubernetes-sigs/cluster-api/releases/download/${CAPI_VERSION}/clusterctl-linux-amd64
sudo chmod +x /usr/local/bin/clusterctl
export EXP_CLUSTER_RESOURCE_SET=true
export CLUSTER_TOPOLOGY=true
clusterctl init \
  --core cluster-api:${CAPI_VERSION} \
  --bootstrap kubeadm:${CAPI_VERSION} \
  --control-plane kubeadm:${CAPI_VERSION} \
  --infrastructure openstack:${CAPO_VERSION}

set_boot_device

trap "" TERM INT EXIT
add_status info "DEPLOYMENT COMPLETED SUCCESSFULLY"
