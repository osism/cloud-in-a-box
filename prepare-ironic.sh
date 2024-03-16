#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

export INTERACTIVE=false

cd /opt/openstackclient/data

wget https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos9-stable-2023.2.initramfs
wget https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos9-stable-2023.2.kernel

docker cp ipa-centos9-stable-2023.2.initramfs kolla-ansible:/share/ironic
docker cp ipa-centos9-stable-2023.2.kernel kolla-ansible:/share/ironic

cp ipa-centos9-stable-2023.2.initramfs /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.initramfs
cp ipa-centos9-stable-2023.2.kernel /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.kernel

osism apply ironic

openstack --os-cloud admin image create \
  --disk-format aki \
  --container-format aki \
  --public \
  --file /data/ipa-centos9-stable-2023.2.initramfs \
  deploy-vmlinuz

openstack --os-cloud admin image create \
  --disk-format ari \
  --container-format ari \
  --public \
  --file /data/ipa-centos9-stable-2023.2.kernel \
  deploy-initrd
