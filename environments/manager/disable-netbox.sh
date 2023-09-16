#!/usr/bin/env bash

sed -i "/netbox_enable:/d" /opt/cloud-in-a-box/environments/manager/configuration.yml
sed -i "/netbox_enable:/d" /opt/configuration/environments/manager/configuration.yml
