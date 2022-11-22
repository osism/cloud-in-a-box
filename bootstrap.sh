#!/usr/bin/env bash

export INTERACTIVE=false

apt-get update
apt-get install -y python3-virtualenv sshpass

cp /opt/cloud-in-a-box/environments/kolla/certificates/ca/cloud-in-a-box.crt /usr/local/share/ca-certificates/
update-ca-certificates

firstip_address=$(hostname --all-ip-addresses | awk '{print $1}')
first_network_interface=$(ip -br -4 a sh | grep ${firstip_address} | awk '{print $1}')

find /opt/cloud-in-a-box -type f -exec sed -i "s/eno1/${first_network_interface}/g" {} \;

pushd /opt/cloud-in-a-box/environments/manager

./run.sh operator \
  -e ansible_ssh_pass=password \
  -e ansible_ssh_user=ubuntu \
  -e ansible_become_password=password

export INSTALL_ANSIBLE_ROLES=false
./run.sh network
netplan apply

./run.sh bootstrap

# NOTE: hackish workaround for initial permission denied issues
chmod o+rw /var/run/docker.sock

./run.sh configuration

find /opt/configuration -type f -exec sed -i "s/eno1/${first_network_interface}/g" {} \;

./run.sh traefik
./run.sh netbox
./run.sh manager

popd

osism apply bootstrap

# NOTE: Restart the manager services to update the /etc/hosts file
docker compose -f /opt/manager/docker-compose.yml restart

# NOTE(berendt): wait for ara-server service
wait_for_container_healthy 60 manager-ara-server-1
