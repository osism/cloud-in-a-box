#!/usr/bin/env bash
set -x
set -e

# This script is only necessary if you are using the Cloud in a Box
# repository on a preinstalled Ubuntu and the osism/node image has
# not served as the basis for it.

for service in apt-daily-upgrade.timer apt-daily.timer motd-news.timer multipathd.socket multipathd.service ufw.service unattended-upgrades.service; do
    if systemctl is-active --quiet multipathd.socket; then
        systemctl stop multipathd.socket
        systemctl disable multipathd.socket
    fi
done

apt-get update
apt-get purge --yes \
  apport \
  apport-symptoms \
  bolt \
  btrfs-progs \
  frr \
  ftp \
  landscape-common \
  lxd-agent-loader \
  modemmanager \
  ntfs-3g \
  open-iscsi \
  open-vm-tools \
  packagekit \
  pastebinit \
  plymouth \
  plymouth-theme-ubuntu-text \
  snapd \
  telnet \
  tnftp \
  ubuntu-advantage-tools \
  xauth
apt-get autoremove --yes --purge

if [[ -e /swap.img ]]; then
    swapoff /swap.img
    rm /swap.img
    sed -i '/swap.img/d' /etc/fstab
fi
