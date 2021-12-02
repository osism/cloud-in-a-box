<p align="center">
  <img src="https://raw.githubusercontent.com/osism/gaia-x-hackathon-2021/main/assets/banner.jpg" alt="Gaia-X Hackathon #2" />
</p>

Registration is required to participate in the hackathon: https://mautic.cloudandheat.com/gaiaxhackathon2

# Target of this hackathon track

The target of this hackathon track is to deploy OpenStack and Ceph with the
help of OSISM on given bare-metal systems pre-installed with Ubuntu 20.04.
A hyperconverged infrastructure (HCI) is being built.

The configuration and installation is done manually to get as much of the
whole process as possible. It is intended as a one-shot deployment.

# Requirements

The following minimum configuration is recommended, with the idea of using
the installed testbed for further testing with Kubernetes, for example, after
the hackathon.

* 256GB RAM
* 2 CPU sockets
* 2 HDD/SSD/NVMe >=1TB (for the operating system)
* 4 HDD/SSD/NVMe >=4TB (for Ceph)
* 2 >= 1 GBit NICs (for the control plane)
* 2 >= 10/25/40/100 GBit NICs (for the data plane)

The minimum recommendations listed are not the minimum requirements of the
solution itself. They are significantly lower.

The configuration in this repository with Ceph & OpenStack can be operated on
a system with 64 GByte RAM, 2x 240 GByte SSDs and an Intel(R) Xeon(R) CPU D-1518.

```
dragon@testbed-node-0:~$ free -m
              total        used        free      shared  buff/cache   available
Mem:          64220       10212       36672          67       17335       41400
Swap:          8191           0        8191
dragon@testbed-node-0:~$ uptime
 20:59:55 up  2:30,  1 user,  load average: 1.35, 1.84, 2.13
```

# Preparations

The systems are to be pre-installed with [Ubuntu 20.04](https://docs.osism.tech/deployment/manual-installation-screenshots.html#ubuntu-manual-installation-screenshots).
The [manager appliance](https://github.com/osism/manager-installer) can also be
used as an alternative.

The systems must be able to reach each other via SSH. It is assumed that the
default user ``ubuntu`` is present and usable on every system.

It is assumed that the network is already configured so that services like
NTP and DNS are usable and external connectivity to external services like
Quay or GitHub is possible. It is not part of the track to perform an airgapped
installation, integrate network equipment etc. pp.

The disks that are to be used for Ceph must be empty. Really empty. Check in
advance. (``wipefs -a -f /dev/sdb``)

It is assumed that the hardware equipment is identical on all systems and in
particular the names of the NICs and block devices are the same everywhere.

# Overview

<img src="https://raw.githubusercontent.com/osism/gaia-x-hackathon-2021/main/assets/overview.drawio.png" alt="Overview" />

The systems, we assume up to five of them, are named ``testbed-node-0`` to ``testbed-node-4``.

``testbed-node-0`` will be used as manager and seed node. Monitoring also runs there.

``testbed-node-0`` to ``testbed-node-2`` will be used as control nodes.

``testbed-node-0`` to ``testbed-node-4`` will be used as resource nodes.

## Manager

The manager is the central control unit of the installation.

<img src="https://raw.githubusercontent.com/osism/gaia-x-hackathon-2021/main/assets/manager-services.drawio.png" alt="Manager Services" />

# Step 1: Prepare configuration

In this prepared configuration, ``testbed.osism.xyz`` is used as the FQDN.

``api.testbed.osism.xyz`` is used as the name for the API.

Create a fork of this repository. Then make adjustments to this fork.

In ``environments/manager/configuration.yml`` set the ``configuration_git_repository``
parameter on the name of the fork.

Uncomment in ``inventory/20-roles`` the nodes that are available

The network configuration and the IP addresses and CIDRs used are adjusted accordingly.

The same applies to the block devices that are to be used for Ceph.

If you want to use different hostnames you have to change all occurences.

```
grep -r testbed-
find . -name 'testbed-*'
```

After completing this step, a finished configuration repository is available.

# Step 2: Solve chicken egg problem (seed phase)

One of the systems is declared as the manager. ``testbed-node-0`` by default.
This must be prepared so that the manager can run there to perform the rest
of the deployment.

At first necessary packages are installed.

```
sudo apt install python3-virtualenv git sshpass
```

Instead of the ``gaia-x-hackathon-2021`` repository you take the created fork
accordingly.

```
git clone https://github.com/osism/gaia-x-hackathon-2021 $HOME/configuration
cd $HOME/configuration/environments/manager
```

Then the necessary deployment user is created.

```
# ANSIBLE_BECOME_ASK_PASS=true \
ANSIBLE_ASK_PASS=true \
ANSIBLE_USER=ubuntu \
./run.sh operator
```

* ``ANSIBLE_USER=ubuntu`` -- the user to be used to log in
* ``ANSIBLE_ASK_PASS=true`` -- asks for the password of the ``ANSIBLE_USER``
* ``ANSIBLE_BECOME_ASK_PASS=true`` -- asks for the password to use sudo

If the network is to be managed as well, ``./run.sh network`` is executed
at this point. By default, new network settings are not applied. A reboot
of the system can be performed with ``./run.sh reboot``.

Now the manager is bootstrapped and deployed.

```
./run.sh bootstrap
./run.sh configuration
./run.sh netbox
./run.sh manager
```

After this step is completed, a usable manager is available.

Finally, a reboot with ``./run.sh reboot`` should be performed.

# Step 3: Bootstrap system(s)

From this point on, the deploy user ``dragon`` is used.

If necessary, the network is prepared.

```
osism apply network
osism apply reboot -- -l 'all:!testbed-node-0.testbed.osism.xyz' -e ireallymeanit=yes
osism apply wait-for-connection -- -l 'all:!testbed-node-0.testbed.osism.xyz'
```

Then the bootstrap takes place.

```
osism apply bootstrap
```

After this step is completed, all systems are ready to launch services.

# Step 4: Deploy services

## Required services like MariaDB, RabbitMQ, Logging, ..

```
osism apply homer
osism apply common
osism apply haproxy
osism apply elasticsearch
osism apply kibana
osism apply openvswitch
osism apply ovn
osism apply memcached
osism apply redis
osism apply etcd
osism apply mariadb
osism apply phpmyadmin
osism apply rabbitmq
```

After completing this step, all necessary services such as database or queuing are available.

## Ceph

Deploying Swift/S3 API using RGW or CephFS is not included in this deployment.

```
osism apply ceph-mons
osism apply ceph-mgrs
osism apply ceph-osds
osism apply ceph-crash
```

After this step is complete, Ceph is available as storage backend.

### Make Ceph keys known in the configuration

After deploying Ceph, the keys generated during the deployment must currently be stored
in the configuration repository. In the future, these keys will be automatically stored
on the integrated Vault service. The task ``Fetch ceph keys from the first monitor node``
takes some time.

```
osism-run custom fetch-ceph-keys
osism apply cephclient
```

## OpenStack

```
osism apply keystone
osism apply horizon
osism apply placement
osism apply glance
osism apply cinder
osism apply neutron
osism apply nova
osism apply octavia
osism apply barbican
osism apply openstackclient
```

Once this step is complete, OpenStack is available as an Infrastructure as a Service layer.

## Monitoring

```
osism apply prometheus
osism apply grafana
osism apply netdata
```

After this step is completed, telemetry data can be displayed visually.

# Notes

If you have found a bug, a feature is missing or you have a question just open a
bug in [osism/issues](https://github.com/osism/issues). We will then move it to
the right place and assign it as soon as possible.
