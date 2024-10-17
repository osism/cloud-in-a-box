cd /opt/openstackclient/data

wget https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos9-stable-2023.2.initramfs
wget https://tarballs.opendev.org/openstack/ironic-python-agent/dib/files/ipa-centos9-stable-2023.2.kernel

docker cp ipa-centos9-stable-2023.2.initramfs kolla-ansible:/share/ironic
docker cp ipa-centos9-stable-2023.2.kernel kolla-ansible:/share/ironic

cp ipa-centos9-stable-2023.2.initramfs /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.initramfs
cp ipa-centos9-stable-2023.2.kernel /opt/configuration/environments/kolla/files/overlays/ironic/ironic-agent.kernel

osism apply ironic

openstack --os-cloud admin image create --disk-format aki --container-format aki --public \
  --file /data/ipa-centos9-stable-2023.2.initramfs deploy-vmlinuz

openstack --os-cloud admin image create --disk-format ari --container-format ari --public \
  --file /data/ipa-centos9-stable-2023.2.kernel deploy-initrd

openstack --os-cloud admin image show -f value -c id deploy-vmlinuz
openstack --os-cloud admin image show -f value -c id deploy-initrd

openstack --os-cloud admin flavor create my-baremetal-flavor \
  --ram 32768 --disk 200 --vcpus 8 \
  --property resources:CUSTOM_BAREMETAL_RESOURCE_CLASS=1 \
  --property resources:VCPU=0 \
  --property resources:MEMORY_MB=0 \
  --property resources:DISK_GB=0

openstack --os-cloud admin baremetal node create --driver ipmi --name baremetal-node \
  --driver-info ipmi_port=623 --driver-info ipmi_username=ADMIN \
  --driver-info ipmi_password=ADMIN \
  --driver-info ipmi_address=192.168.88.254 \
  --resource-class baremetal-resource-class --property cpus=8 \
  --property memory_mb=32768 --property local_gb=200 \
  --property cpu_arch=x86_64 \
  --driver-info deploy_kernel=4e268807-f381-4d98-8dd9-61ed5f2163cb \
  --driver-info deploy_ramdisk=f6da7716-7765-4814-bd63-831c9fad2f1f

openstack --os-cloud admin baremetal node show baremetal-node -f value -c uuid

openstack --os-cloud admin baremetal port create 00:25:90:ba:b4:45 \
  --node 403dfb04-8157-4ddb-a3a4-539b06612fee \
  --physical-network physnet1

openstack --os-cloud admin baremetal port create 00:25:90:ba:b4:44 \
  --node 403dfb04-8157-4ddb-a3a4-539b06612fee

openstack --os-cloud admin baremetal node power on 403dfb04-8157-4ddb-a3a4-539b06612fee
openstack --os-cloud admin baremetal node power off 403dfb04-8157-4ddb-a3a4-539b06612fee

openstack --os-cloud admin baremetal introspection start 403dfb04-8157-4ddb-a3a4-539b06612fee
openstack --os-cloud admin baremetal introspection status 403dfb04-8157-4ddb-a3a4-539b06612fee
openstack --os-cloud admin baremetal introspection abort 403dfb04-8157-4ddb-a3a4-539b06612fee

openstack --os-cloud admin baremetal node manage 403dfb04-8157-4ddb-a3a4-539b06612fee
openstack --os-cloud admin baremetal node provide 403dfb04-8157-4ddb-a3a4-539b06612fee

openstack --os-cloud admin server create --image "Cirros 0.6.2" --flavor my-baremetal-flavor \
  --network public demo1
