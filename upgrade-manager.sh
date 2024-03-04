#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

set -x
set -e

export INTERACTIVE=false
source /etc/cloud-in-a-box.env

# The normal way of updating the configuration repository (osism apply configuration)
# is not used as we have made manual changes in the configuration repository
# on the Cloud in a Box. For example, for the primary network card.
pushd /opt/configuration
git pull
popd

osism update manager
