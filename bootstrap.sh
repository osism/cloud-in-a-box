#!/usr/bin/env bash

export INTERACTIVE=false

apt-get update
apt-get install -y python3-virtualenv sshpass

cp /opt/cloud-in-a-box/environments/kolla/certificates/ca/cloud-in-a-box.crt /usr/local/share/ca-certificates/
update-ca-certificates

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
./run.sh traefik
./run.sh netbox
./run.sh manager

popd

osism apply bootstrap
