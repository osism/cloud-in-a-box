#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y python3-virtualenv sshpass

pushd environments/manager

./run.sh operator -e ansible_ssh_pass=install -e ansible_ssh_user=install
./run.sh bootstrap
./run.sh configuration
./run.sh netbox
./run.sh manager
./run.sh reboot

popd
