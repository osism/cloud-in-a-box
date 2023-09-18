#!/usr/bin/env bash
set -x
set -e

export INTERACTIVE=false

if [[ -e /etc/cloud-in-a-box.env ]]; then
    source /etc/cloud-in-a-box.env
else
    CLOUD_IN_A_BOX_TYPE=${1:-sandbox}
    echo "CLOUD_IN_A_BOX_TYPE=$CLOUD_IN_A_BOX_TYPE" | sudo tee /etc/cloud-in-a-box.env
fi

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
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder
osism apply designate
osism apply octavia

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    osism apply barbican
    osism apply grafana
    osism apply phpmyadmin
    osism apply homer
fi

osism apply --environment openstack bootstrap-ceph-rgw

osism apply netdata
osism apply openstackclient

osism apply wireguard

mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
sed -i -e "s/CHANGEME - dragon private key/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(hostname --all-ip-addresses | awk '{print $1}')/ /home/dragon/wireguard-client.conf

sudo ip addr add dev br-ex 192.168.112.10/24
sudo ip link set up dev br-ex
osism apply --environment custom workarounds

osism apply --environment openstack bootstrap-$CLOUD_IN_A_BOX_TYPE
osism manage images --cloud admin --filter Cirros
osism manage images --cloud admin --filter "Ubuntu 22.04 Minimal"

osism apply k3s

# NOTE: The following lines will be moved to an osism.services.clusterapi role
export KUBECONFIG=$HOME/.kube/config
kubectl label node manager openstack-control-plane=enabled
sudo curl -Lo /usr/local/bin/clusterctl https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.4.4/clusterctl-linux-amd64
sudo chmod +x /usr/local/bin/clusterctl
export EXP_CLUSTER_RESOURCE_SET=true
export CLUSTER_TOPOLOGY=true
clusterctl init \
  --core cluster-api:v1.4.4 \
  --bootstrap kubeadm:v1.4.4 \
  --control-plane kubeadm:v1.4.4 \
  --infrastructure openstack:v0.7.1
