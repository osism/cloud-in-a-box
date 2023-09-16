#!/usr/bin/env bash
set -x
set -e

# This script is only necessary if you are using the Cloud in a Box
# repository on a preinstalled Ubuntu and the osism/node image has
# not served as the basis for it.

apt purge --yes snapd modemmanager lxd-agent-loader
apt purge --yes plymouth plymouth-theme-ubuntu-text
apt purge --yes ubuntu-advantage-tools xauth landscape-common btrfs-progs
apt purge --yes apport apport-symptoms open-vm-tools ntfs-3g
apt purge --yes telnet pastebinit tnftp ftp open-iscsi bolt packagekit
apt autoremove --yes --purge

systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily.timer
systemctl disable motd-news.timer
systemctl disable ufw.service
systemctl disable unattended-upgrades.service

if [[ -e /swap.img ]]; then
    swapoff /swap.img
    rm /swap.img
    sed -i '/swap.img/d' /etc/fstab
fi
