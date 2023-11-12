#!/usr/bin/env bash

set -e

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

set -x

trap "echo 'BOOTSTRAP FAILED'" TERM INT EXIT
export INTERACTIVE=false
CLOUD_IN_A_BOX_TYPE=${1:-sandbox}

wait_for_uplink_connection "https://scs.community"

apt-get update
apt-get install -y python3-virtualenv sshpass jq

default_gateway_interface="$(get_ethernet_interface_of_default_gateway)"
get_default_gateway_settings

cp /opt/cloud-in-a-box/environments/kolla/certificates/ca/cloud-in-a-box.crt /usr/local/share/ca-certificates/
update-ca-certificates

find /opt/cloud-in-a-box -type f -not -name "*.sh" -exec sed -i "s/eno1/${default_gateway_interface}/g" {} +
pushd /opt/cloud-in-a-box/environments/manager

./run.sh operator \
  -e ansible_ssh_pass=password \
  -e ansible_ssh_user=osism \
  -e ansible_become_password=password

export INSTALL_ANSIBLE_ROLES=false
./run.sh network

# NOTE: Apply network changes without rebooting
netplan apply

# NOTE: Ensure the APT cache is always up to date
apt-get update

./run.sh bootstrap

# NOTE: hackish workaround for initial permission denied issues
chmod o+rw /var/run/docker.sock

./run.sh configuration

find /opt/configuration -type f -exec sed -i "s/eno1/${default_gateway_interface}/g" {} +

if [[ $CLOUD_IN_A_BOX_TYPE == "edge" ]]; then
    sed -i "/octavia_network_type:/d" /opt/configuration/environments/kolla/configuration.yml
    echo 'octavia_provider_drivers: "ovn:OVN provider"' >> /opt/configuration/environments/kolla/configuration.yml
    echo 'octavia_provider_agents: ovn' >> /opt/configuration/environments/kolla/configuration.yml
fi

./run.sh traefik

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    ./run.sh netbox
elif [[ $CLOUD_IN_A_BOX_TYPE == "edge" ]]; then
    ./disable-netbox.sh
fi
./run.sh pull
./run.sh manager

popd

# NOTE: In some configurations, the manager service is currently not coming up properly.
#       We therefore perform another explicit restart of the manager service here.
systemctl restart docker-compose@manager

# NOTE: wait for the manager services
wait_for_container_healthy 60 osism-ansible
wait_for_container_healthy 60 ceph-ansible
wait_for_container_healthy 60 kolla-ansible
wait_for_container_running 60 osismclient

# NOTE: gather facts to ensure that the addresses of the new VLAN devices
#       are in the facts cache
osism apply facts

osism apply bootstrap

# Before the 6.1.0 release of OSISM, the execution of the limits play is
# not yet part of the bootstrap play. Can be removed after the release of
# OSISM 6.1.0.
osism apply limits

# NOTE: Restart the manager services to update the /etc/hosts file
docker compose -f /opt/manager/docker-compose.yml restart

# NOTE: wait for the manager service
wait_for_container_healthy 60 manager-ara-server-1

trap "" TERM INT EXIT
echo "BOOTSTRAP COMPLETE"
