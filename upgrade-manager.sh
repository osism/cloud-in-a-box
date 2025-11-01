#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

trap "set +x; add_status 'error' 'MANAGER UPGRADE FAILED'" TERM INT EXIT

set -x
set -e

export INTERACTIVE=false
source /etc/cloud-in-a-box.env

add_status "info" "MANAGER UPGRADE STARTED"

# The normal way of updating the configuration repository (osism sync configuration)
# is not used as we have made manual changes in the configuration repository
# on the Cloud in a Box. For example, for the primary network card.
pushd /opt/configuration
git pull
popd

osism update manager

osism apply cleanup-docker-images -e ireallymeanit=yes

trap "" TERM INT EXIT
add_status "info" "MANAGER UPGRADE COMPLETED"
