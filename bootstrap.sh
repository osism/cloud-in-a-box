#!/usr/bin/env bash

apt-get update
apt-get install -y python3-virtualenv sshpass

pushd /opt/cloud-in-a-box/environments/manager

./run.sh operator \
  -e ansible_ssh_pass=password \
  -e ansible_ssh_user=ubuntu \
  -e ansible_become_password=password

export INSTALL_ANSIBLE_ROLES=false
./run.sh network
ip link add link eno1 name vlan100 type vlan id 100
netplan apply
./run.sh bootstrap
./run.sh configuration
./run.sh manager

popd

osism apply bootstrap
