# Cloud in a Box

Cloud in a Box is a minimalistic installation of OSISM with only services which are needed to
make it usable with Kubernetes. It is intended for use as a development
system on bare-metal or for use in edge environments.

For more information you can consult the [Testbed](https://docs.scs.community/docs/category/osism-testbed)
documentation. If you want to build a more complex enviornment have a look at the
[OSISM](https://docs.osism.tech/) documentation.

:::warning

The secrets are stored in plain text and are not secure. Do not use for public
accessible systems.

:::

## Requirements

* The first blockdevice is available as `/dev/sda` or `/dev/nvme0n1`.
* USB stick with at least 2 GByte capacity.
* CPU: 1 socket, 4 cores
* RAM: 32 GByte
* Storage: 1 TByte
* Network: 1 network interface (optional: 2nd network interface for external connectivity)

## Installation

1. Download the Cloud in a Box image.

   :::warning

   When booting from this image, all data on the hard disks will be destroyed
   without confirmation.

   :::

   * <https://minio.services.osism.tech/node-image/ubuntu-autoinstall-cloud-in-a-box-1.iso> (with /dev/sda)
   * <https://minio.services.osism.tech/node-image/ubuntu-autoinstall-cloud-in-a-box-2.iso> (with /dev/nvme0n1)

2. Use a tool like balenaEtcher or dd to create a bootable USB stick with the Cloud
   in a Box image.

3. Boot from the USB stick. Make sure that the boot from USB is activated in the BIOS.

4. The installation will start and take a few minutes. After that the system will shutdown.

5. Remove the USB stick and restart the system.

6. The deployment will start. This takes some time and the system will shutdown when the
   deployment is finished. This takes roughly an hour, possibly longer depending on the
   hardware and internet connection.

7. System is ready for use, by default DHCP is tried on the first network device.

8. Login via SSH. Use the user `dragon` with the password `password`.

   ```bash
   ssh dragon@IP_FROM_YOUR_SERVER
   ```

## Connectivity with Wireguard

Copy the `/home/dragon/wireguard-client.conf` file to your workstation. This is necessary
for using the web endpoints on your workstation. Rename the wireguard config file to something
like `cloud-in-a-box.conf`.

If you want to connect to the Cloud in a Box system from multiple clients, change the client IP
address in the config file to be different on each client.

```bash
scp dragon@IP_FROM_YOUR_SERVER:/home/dragon/wireguard-client.conf /home/ubuntu/cloud-in-a-box.conf
```

Install wireguard on your workstation, if you have not done this before. For instructions how to do
it on your workstation, please have a look on the documentation of your used distribution. The
wireguard documentation you will find [here](https://www.wireguard.com/).

Start the wireguard tunnel.

```bash
wg-quick up /home/ubuntu/cloud-in-a-box.conf
```

## Usage

Now your Cloud in a Box is up and you can reach the most services via the Homer dashboard:
<https://homer.services.in-a-box.cloud>

If you want to access the services please choose the URL from the following list:

| Name                    | URL                                           | Username   | Password  |
|-------------------------|-----------------------------------------------|------------|-----------|
| ARA                     | <https://ara.services.in-a-box.cloud>         | ara        | password  |
| Flower                  | <https://flower.services.in-a-box.cloud>      | -          | -         |
| Grafana                 | <https://api.in-a-box.cloud:3000>             | admin      | password  |
| Homer                   | <https://homer.services.in-a-box.cloud>       | -          | -         |
| Horizon - admin project | <https://api.in-a-box.cloud>                  | admin      | password  |
| Horizon - test project  | <https://api.in-a-box.cloud>                  | test       | test      |
| OpenSearch Dashboards   | <https://api.in-a-box.cloud:5601>             | opensearch | password  |
| Netbox                  | <https://netbox.services.in-a-box.cloud>      | admin      | password  |
| Netdata                 | <http://manager.systems.in-a-box.cloud:19999> | -          | -         |
| phpMyAdmin              | <https://phpmyadmin.services.in-a-box.cloud>  | root       | password  |
| RabbitMQ                | <https://api.in-a-box.cloud:15672>            | openstack  | password  |

:::note

Netdata is currently only usable via HTTP and not via HTTPS.

:::

### OpenStack CLI

Connect to your Cloud in a Box via SSH (see command above).

Select one of the preconfigured environments `system`, `admin`, or `test`
by exporting the environment variable `OS_CLOUD`:

```bash
export OS_CLOUD=admin
openstack server list
```

### Import of additional images

For example to import the Garden Linux image this command can be used:

```bash
export OS_CLOUD=admin
osism manage images --filter 'Garden Linux'
```

All available images: <https://github.com/osism/openstack-image-manager/tree/main/etc/images>

### Upgrade

To upgrade the Cloud-in-a-Box, proceed as follows. It is best to execute the commands within a
screen session, it takes some time. Please note that you cannot update the Ceph deployment at
the moment. This will be enabled in the future.

```bash
osism apply configuration
/opt/configuration/upgrade.sh
docker system prune -a
```

### Use of 2nd NIC for external network

In the default configuration, the Cloud in a Box is built in such a way that an internal
VLAN101 is used as an simulated external network and this is made usable via the 1st network
interface using masquerading. This makes it possible for instances running on the Cloud
in a Box to reach the internet. The disadvantage of this is that the instances themselves
can only be reached via floating IP addresses from the Cloud in a Box system itself or
via the Wireguard tunnel. Especially in edge environments, however, one would usually like
to have this differently and the instances should be directly accessible via the local
network.

To make this work, first identify the name of a 2nd network card to be used.

```bash
dragon@manager:~$ sudo lshw -class network -short
H/W path          Device          Class          Description
============================================================
/0/100/2.2/0      eno7            network        Ethernet Connection X552 10 GbE SFP+
/0/100/2.2/0.1    eno8            network        Ethernet Connection X552 10 GbE SFP+
/0/100/1c/0       eno1            network        I210 Gigabit Network Connection
/0/100/1c.1/0     eno2            network        I210 Gigabit Network Connection
/0/100/1c.4/0     eno3            network        I350 Gigabit Network Connection
/0/100/1c.4/0.1   eno4            network        I350 Gigabit Network Connection
/0/100/1c.4/0.2   eno5            network        I350 Gigabit Network Connection
/0/100/1c.4/0.3   eno6            network        I350 Gigabit Network Connection
```

In the following we use `eno7`. Activate the device manually with  `sudo ip link set up dev eno7`.
Then check that a link is actually present.

```
dragon@manager:~$ ethtool eno7
Settings for eno7:
	Supported ports: [ FIBRE ]
	Supported link modes:   10000baseT/Full
[...]
	Link detected: yes
```

Now this device is made permanently known in the network configuration. Select the MTU
accordingly. For 1 GBit rather `1500` than `9100`.

* `/opt/configuration/inventory/group_vars/generic/network.yml`
* `/opt/configuration/environments/manager/group_vars/manager.yml`

```yaml
network_ethernets:
  eno1:
    dhcp4: true
  eno7:
    mtu: 9100
```

Then, this change is deployed and applied.

```bash
osism apply network
sudo netplan apply
```

Now the configuration for Neutron and OVN is prepared. `network_workload_interface`
is expanded by the 2nd network interface. The order is not random, first `vlan101`
then `eno7`. `neutron_bridge_name` is added.

* `/opt/configuration/inventory/group_vars/generic/network.yml`
* `/opt/configuration/environments/manager/group_vars/manager.yml`

```yaml
network_workload_interface: "vlan101,eno7"
neutron_bridge_name: "br-ex,br-add"
```

Then, this change is deployed.

```bash
osism reconciler sync
osism apply openvswitch
osism apply ovn
osism apply neutron
```

Now segments and/or subnets can be configured. In this case, `eno7` is configured as an
untagged port on the remote side.

* `/opt/configuration/environments/openstack/playbook-additional-public-network.yml`

```yaml
- name: Create additional public network
  hosts: localhost
  connection: local

  tasks:
    - name: Create additional public network
      openstack.cloud.network:
        cloud: admin
        state: present
        name: public-add
        external: true
        provider_network_type: flat
        provider_physical_network: physnet2

    - name: Create additional public subnet
      openstack.cloud.subnet:
        cloud: admin
        state: present
        name: subnet-public-add
        network_name: public-add
        cidr: 192.168.23.0/24
        enable_dhcp: false
        allocation_pool_start: 192.168.23.100
        allocation_pool_end: 192.168.23.200
        gateway_ip: 192.168.23.1
        dns_nameservers:
          - 8.8.8.8
          - 9.9.9.9
```

The additional public network can now be made known with
`osism apply -e openstack additional-public-network`.

There is now a 2nd floating IP address pool with the name `public-add`
available for use. If instances are to be started directly in this network,
`enable_dhcp: true` must be set. In this case, it should be clarified in
advance with the provider of the external network whether the use of DHCP
is permitted there.

## Troubleshooting

![Broken disk setup](./images/broken_disk_setup.png)

This error means that your disk setup is broken. Use `cfdisk` and delete all partitions on
the system on which you want to install the Cloud in a Box image.

With `lsblk` you can verify if the partitions are empty.

## Notes

If you have found a bug, a feature is missing or you have a question just open an issue on GitHub
in [osism/cloud-in-a-box](https://github.com/osism/cloud-in-a-box/issues). We will have a look on
it as soon as it is possible.
