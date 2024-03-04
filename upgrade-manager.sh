#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

set -x
set -e

export INTERACTIVE=false
source /etc/cloud-in-a-box.env

osism apply configuration
osism update manager
