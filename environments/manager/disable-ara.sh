#!/usr/bin/env bash

sed -i "/ara_enable:/d" /opt/cloud-in-a-box/environments/manager/configuration.yml
sed -i "/ara_enable:/d" /opt/configuration/environments/manager/configuration.yml

echo "ara_enable: false" >> /opt/cloud-in-a-box/environments/manager/configuration.yml
echo "ara_enable: false" >> /opt/configuration/environments/manager/configuration.yml
