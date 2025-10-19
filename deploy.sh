#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "set +x; add_status 'error' 'DEPLOY FAILED'; sleep 90" TERM INT EXIT
set -x
set -e

export INTERACTIVE=false
export OSISM_APPLY_RETRY=1

if [[ -e /etc/cloud-in-a-box.env ]]; then
    source /etc/cloud-in-a-box.env
else
    CLOUD_IN_A_BOX_TYPE=${1:-sandbox}
    echo "CLOUD_IN_A_BOX_TYPE=$CLOUD_IN_A_BOX_TYPE" | sudo tee /etc/cloud-in-a-box.env
fi

osism sync facts

# Minified version of the Cloud in a Box in which only Kubernetes is deployed.
if [[ $CLOUD_IN_A_BOX_TYPE == "kubernetes" ]]; then
    # Deploy kubernetes
    osism apply kubernetes

    # Deploy kubernetes dashboard
    osism apply k8s-dashboard

    # Deploy netdata
    osism apply netdata

    # Deploy netbird
    if [[ ! -z "$NB_SETUP_KEY" ]]; then
        echo "netbird_hostname: vice-$(head -c 8 /etc/machine-id)" >> /opt/configuration/environments/infrastructure/configuration.yml
        echo "netbird_setup_key: $NB_SETUP_KEY" >> /opt/configuration/environments/infrastructure/configuration.yml
        if [[ ! -z "$NB_MANAGEMENT_URL" ]]; then
            echo "netbird_management_url: $NB_MANAGEMENT_URL" >> /opt/configuration/environments/infrastructure/configuration.yml
        fi
        osism apply netbird
    fi

    # Enable ARA service
    /opt/configuration/enable-ara.sh

    trap "" TERM INT EXIT
    add_status info "DEPLOYMENT COMPLETED SUCCESSFULLY"

    exit 0
fi

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

# In the CI environment, no Volume Group (VG) is created. Instead, a
# loopback device is used.
vgdisplay osd-vg > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    dd if=/dev/zero of=/opt/loopback.img bs=1G count=50
    losetup /dev/loop0 /opt/loopback.img
    pvcreate /dev/loop0
    vgcreate osd-vg /dev/loop0
fi

# Create LVs for Ceph since that is currently not possible with Curtin
# with percentages. The VG osd-vg itself is already created by Curtin.
if [[ ! -e /dev/osd-vg/osd-1 ]]; then
    osism apply --environment custom create-logical-volumes
fi

osism sync inventory

# Deploy Ceph services
osism apply ceph
osism apply ceph-pools
osism sync ceph-keys
osism apply cephclient
osism apply ceph-bootstrap-dashboard

# Deploy OpenStack services
osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder
osism apply designate
osism apply octavia
osism apply openstackclient

# Make Swift API endpoint available
osism apply kolla-ceph-rgw

# Upload octavia amphora image
osism manage image octavia

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply skyline
    osism apply barbican
    osism apply prometheus
    osism apply grafana
    osism apply phpmyadmin
    osism apply cgit
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
osism manage images --cloud admin --filter "Ubuntu 24.04"

# Create machine types
osism manage flavors

# Create test project (without a server and attached volume)
osism apply --environment openstack test --skip-tags test-server,test-volume

# Deploy kubernetes
osism apply kubernetes

# Deploy kubernetes dashboard
osism apply k8s-dashboard

# Deploy clusterapi
osism apply clusterapi

# Deploy magnum
osism apply copy-kubeconfig
osism apply magnum

touch /etc/cloud/cloud-init.disabled

# Enable ARA service
/opt/configuration//enable-ara.sh

trap "" TERM INT EXIT
add_status info "DEPLOYMENT COMPLETED SUCCESSFULLY"
