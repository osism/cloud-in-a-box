#!/usr/bin/env bash

echo "INIT"
set -x

VALID_CLOUD_IN_A_BOX_TYPES=("edge" "kubernetes" "sandbox")

CLOUD_IN_A_BOX_TYPE=$1
shift

if [[ -z $CLOUD_IN_A_BOX_TYPE ]]; then
  # No type was specified, use sandbox as default
  CLOUD_IN_A_BOX_TYPE=sandbox
else
  # Check if it is a valid type
  if [[ " ${VALID_CLOUD_IN_A_BOX_TYPES[*]} " != *" $CLOUD_IN_A_BOX_TYPE "* ]]; then
    echo "ERROR: Invalid type $CLOUD_IN_A_BOX_TYPE specified."
    exit 1
  fi

  # Write parameters
  for extra in "$@"; do
    echo "$extra" | tee -a /etc/cloud-in-a-box.env
  done
fi

echo "CLOUD_IN_A_BOX_TYPE=$CLOUD_IN_A_BOX_TYPE" | tee -a /etc/cloud-in-a-box.env

param_file="/etc/.initial-kernel-commandline"
if ! [ -e "${param_file}" ];then
   param_file="/proc/cmdline"
fi

vars="$(tr ' ' '\n' < $param_file | grep -P '^ciab_.+=.+')"
if [ -n "$vars" ]; then
   eval "$vars"
fi

set -x
set -e

# Get initial configuration repository
git clone "${ciab_repo_url:-https://github.com/osism/cloud-in-a-box}" /opt/cloud-in-a-box
git -C /opt/cloud-in-a-box checkout "${ciab_branch:-main}"

# Run bootstrap script
/opt/cloud-in-a-box/bootstrap.sh $CLOUD_IN_A_BOX_TYPE

# Run deploy script
/opt/cloud-in-a-box/deploy.sh $CLOUD_IN_A_BOX_TYPE
