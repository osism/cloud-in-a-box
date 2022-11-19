# Cloud in a Box

**The secrets are stored in plain text and are not secure. Do not use for public
accessible systems.**

## Assumptions

* the 1st blockdevice is available as ``/dev/sda``
* the 2nd blockdevice is available as ``/dev/sdb``
* the 1st network device is available as ``eno1``
* the 2nd network device is available as ``eno2``

## Download

| :zap: When booting from this image, all data on the hard disks will be destroyed without confirmation. |
|--------------------------------------------------------------------------------------------------------|

* https://minio.services.osism.tech/node-image/ubuntu-autoinstall-4.iso

## Usage

* Copy image to USB stick
* Boot from USB stick
* Installation is performed, system shuts down afterwards
* Remove USB stick and start system
* Deloyment is performed, system shuts down afterwards
* System is ready for use, by default DHCP is tried on
  the 1st network device
* Login via ``dragon`` and ``password``

## Notes

If you have found a bug, a feature is missing or you have a question just open a
bug in [osism/issues](https://github.com/osism/issues). We will then move it to
the right place and assign it as soon as possible.
