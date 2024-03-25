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

# Pull container images
osism apply -e custom pull-container-images

osism apply common
osism apply loadbalancer

# OpenSearch is only required on the sandbox type. On the edge type,
# the logs will be delivered to a central location in the future.
if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply opensearch
fi

# Deploy infrastructure services
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

# Deploy Ceph services
osism apply ceph -e enable_ceph_mds=true -e enable_ceph_rgw=true
osism apply ceph-pools
osism apply copy-ceph-keys
osism apply cephclient
osism apply ceph-bootstrap-dashboard

# Deploy OpenStack services
osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply neutron

# As the deployment of Ironic has been prepared so far, but will only be deployed
# later in a manual step, the service is deactivated here for the moment.
sudo systemctl disable kolla-ironic_neutron_agent-container.service
sudo systemctl stop kolla-ironic_neutron_agent-container.service

osism apply nova
osism apply cinder
osism apply designate
osism apply octavia
osism apply openstackclient

# Make Swift API endpoint available
osism apply kolla-ceph-rgw

# upload octavia amphora image
osism manage image octavia

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply skyline
    osism apply barbican
    osism apply prometheus
    osism apply grafana
    osism apply phpmyadmin
    osism apply homer
    osism apply netdata
fi

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
osism apply kubernetes

# Deploy kubernetes-dashboard
osism apply kubernetes-dashboard

# Deploy clusterapi
osism apply clusterapi

# Deploy magnum
osism apply copy-kubeconfig
osism apply magnum

trap "" TERM INT EXIT
add_status info "DEPLOYMENT COMPLETED SUCCESSFULLY"
