#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "add_status 'error' 'BOOTSTRAP FAILED'" TERM INT EXIT
set -e
set -x

export INTERACTIVE=false

if [[ -e /etc/cloud-in-a-box.env ]]; then
    source /etc/cloud-in-a-box.env
else
    CLOUD_IN_A_BOX_TYPE=${1:-sandbox}
    echo "CLOUD_IN_A_BOX_TYPE=$CLOUD_IN_A_BOX_TYPE" | sudo tee /etc/cloud-in-a-box.env
fi

wait_for_uplink_connection "https://scs.community"

apt-get update
apt-get install -y python3-virtualenv python3-venv sshpass jq

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

# Apply network changes without rebooting
netplan apply

# Ensure the APT cache is always up to date
apt-get update

./run.sh bootstrap

# Hackish workaround for initial permission denied issues
chmod o+rw /var/run/docker.sock

./run.sh configuration

find /opt/configuration -type f -exec sed -i "s/eno1/${default_gateway_interface}/g" {} +

./run.sh traefik

if [[ $CLOUD_IN_A_BOX_TYPE == "sandbox" ]]; then
    ./run.sh netbox
elif [[ $CLOUD_IN_A_BOX_TYPE == "edge" ]]; then
    ./disable-netbox.sh
elif [[ $CLOUD_IN_A_BOX_TYPE == "kubernetes" ]]; then
    # Disable ceph & kolla ansible containers for the initial deployment
    echo "enable_ceph_ansible: false" >> /opt/cloud-in-a-box/environments/manager/configuration.yml
    echo "enable_kolla_ansible: false" >> /opt/cloud-in-a-box/environments/manager/configuration.yml

    # Disable ceph & kolla ansible containers for upgrades
    echo "enable_ceph_ansible: false" >> /opt/configuration/environments/manager/configuration.yml
    echo "enable_kolla_ansible: false" >> /opt/configuration/environments/manager/configuration.yml

    # Use latest manager
    sed -i "s/manager_version: .*/manager_version: latest/g" /opt/cloud-in-a-box/environments/manager/configuration.yml
    sed -i "s/manager_version: .*/manager_version: latest/g" /opt/configuration/environments/manager/configuration.yml

    pushd /opt/cloud-in-a-box
    make sync
    cp /opt/cloud-in-a-box/environments/manager/images.yml /opt/configuration/environments/manager/images.yml
    chown dragon:dragon /opt/configuration/environments/manager/images.yml
    popd
fi

./run.sh pull
./run.sh manager

popd

# In some configurations, the manager service is currently not coming up properly.
# We therefore perform another explicit restart of the manager service here.
systemctl restart docker-compose@manager

# Wait for the manager services
wait_for_container_healthy 60 osism-ansible

if [[ $CLOUD_IN_A_BOX_TYPE != "kubernetes" ]]; then
    wait_for_container_healthy 60 ceph-ansible
    wait_for_container_healthy 60 kolla-ansible
fi

wait_for_container_running 60 osismclient

# Gather facts to ensure that the addresses of the new VLAN devices
# are in the facts cache
osism apply facts

osism apply bootstrap

# Restart the manager services to update the /etc/hosts file
docker compose -f /opt/manager/docker-compose.yml restart

# Wait for the manager service
wait_for_container_healthy 60 manager-ara-server-1

trap "" TERM INT EXIT
add_status "info" "BOOTSTRAP COMPLETE"
