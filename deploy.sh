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
osism apply opensearch
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
ceph osd pool set device_health_metrics crush_rule replicated_rule_ciab

osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply neutron
osism apply nova
osism apply cinder
osism apply designate
osism apply barbican
osism apply octavia

osism apply --environment openstack bootstrap-ceph-rgw

osism apply grafana
osism apply homer
osism apply netdata
osism apply openstackclient
osism apply phpmyadmin

osism apply wireguard

mv /home/dragon/wg0-dragon.conf /home/dragon/wireguard-client.conf
sed -i -e "s/CHANGEME - dragon private key/GEQ5eWshKW+4ZhXMcWkAAbqzj7QA9G64oBFB3CbrR0w=/" /home/dragon/wireguard-client.conf
sed -i -e s/WIREGUARD_PUBLIC_IP_ADDRESS/$(hostname --all-ip-addresses | awk '{print $1}')/ /home/dragon/wireguard-client.conf

sudo ip addr add dev br-ex 192.168.112.10/24
sudo ip link set up dev br-ex
osism apply --environment custom workarounds

osism apply --environment openstack bootstrap

osism manage images --cloud admin --filter Cirros
osism manage images --cloud admin --filter "Ubuntu 22.04 Minimal"
