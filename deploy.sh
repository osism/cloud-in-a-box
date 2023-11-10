#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "echo 'DEPLOY FAILED'" TERM INT EXIT
set -x
set -e

export INTERACTIVE=false

if [[ -e /etc/cloud-in-a-box.env ]]; then
    source /etc/cloud-in-a-box.env
else
    CLOUD_IN_A_BOX_TYPE=${1:-sandbox}
    echo "CLOUD_IN_A_BOX_TYPE=$CLOUD_IN_A_BOX_TYPE" | sudo tee /etc/cloud-in-a-box.env
fi

# On the edge environments we are not interested in the initial Ansible logs.
if [[ $CLOUD_IN_A_BOX_TYPE == "edge" ]]; then
    docker exec -t ceph-ansible mv /ansible/ara.env /ansible/ara.env.disabled || true
    docker exec -t kolla-ansible mv /ansible/ara.env /ansible/ara.env.disabled || true
    docker exec -t osism-ansible mv /ansible/ara.env /ansible/ara.env.disabled || true
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
    lvcreate -n osd-1 -l16%VG osd-vg
    lvcreate -n osd-2 -l16%VG osd-vg
    lvcreate -n osd-3 -l16%VG osd-vg
    lvcreate -n osd-4 -l16%VG osd-vg
    lvcreate -n osd-5 -l16%VG osd-vg
    lvcreate -n osd-6 -l16%VG osd-vg
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
    osism apply grafana
    osism apply phpmyadmin
    osism apply homer
fi

osism apply netdata
osism apply openstackclient

osism apply wireguard

mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
sed -i -e "s/CHANGEME - dragon private key/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(get_v4_ip_of_default_gateway)/ /home/dragon/wireguard-client.conf

sudo ip addr add dev br-ex 192.168.112.10/24
sudo ip link set up dev br-ex
osism apply --environment custom workarounds

osism apply --environment openstack bootstrap-$CLOUD_IN_A_BOX_TYPE
osism manage images --cloud admin --filter Cirros
osism manage images --cloud admin --filter "Ubuntu 22.04 Minimal"

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

# Re-enable the Ansible logs on the edge environments to capture changes after the initial deployment.
if [[ $CLOUD_IN_A_BOX_TYPE == "edge" ]]; then
    docker exec -t ceph-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
    docker exec -t kolla-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
    docker exec -t osism-ansible mv /ansible/ara.env.disabled /ansible/ara.env || true
fi


trap "" TERM INT EXIT
echo "DEPLOY COMPLETE"
