# Cloud in a Box

**The secrets are stored in plain text and are not secure. Do not use for public
accessible systems.**

## Assumptions

* the 1st blockdevice is available as ``/dev/sda`` or ``/dev/nvme0n1``

## Download

| :zap: When booting from this image, all data on the hard disks will be destroyed without confirmation. |
|--------------------------------------------------------------------------------------------------------|

* https://minio.services.osism.tech/node-image/ubuntu-autoinstall-cloud-in-a-box-1.iso (with /dev/sda)
* https://minio.services.osism.tech/node-image/ubuntu-autoinstall-cloud-in-a-box-2.iso (with /dev/nvme0n1)

## Usage

* Copy image to USB stick
* Boot from USB stick
* Installation is performed, system shuts down afterwards
* Remove USB stick and start system
* Deloyment is performed, system shuts down afterwards
* System is ready for use, by default DHCP is tried on
  the 1st network device
* Login via ``dragon`` and ``password``
* There is a ``wireguard-client.conf`` that you can copy over to a client
  to create a tunnel to access to the web interfaces and APIs of the system.
  On the client, adjust the client IP in it (if you want to connect with multiple
  clients, otherwise leave it alone), copy it to ``/etc/wireguard/wg0.conf`` and
  ``wg-quick up wg0`` to start the tunnel.
* Point your browser to the [homer dashboard](https://homer.services.in-a-box.cloud/) for
  the admin web interfaces.
* The installation is a minimalistic single-node installation similar to the
  testbed installation. Consult the [testbed documentation](https://docs.osism.de/testbed/)
  for an overview over the system. Default passwords can be found
  [here](https://docs.osism.de/testbed/usage.html#webinterfaces).

## Notes

If you have found a bug, a feature is missing or you have a question just open a
bug in [osism/issues](https://github.com/osism/issues). We will then move it to
the right place and assign it as soon as possible.
