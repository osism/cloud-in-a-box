#!/bin/bash

echo "INIT"
set -x 

CLOUD_IN_A_BOX_TYPE=${1:-sandbox}

param_file="/etc/.initial-kernel-commandline"
if ! [ -e "${param_file}" ];then
   param_file="/proc/cmdline"
fi

vars="$(tr ' ' '\n' < $param_file |grep -P '^ciab_.+=.+')"
if [ -n "$vars" ];then
   eval "$vars"
fi

set -xe
git clone "${ciab_repo_url:-https://github.com/osism/cloud-in-a-box}" /opt/cloud-in-a-box
git -C /opt/cloud-in-a-box checkout "${ciab_branch:-main}"
/opt/cloud-in-a-box/bootstrap.sh $CLOUD_IN_A_BOX_TYPE
/opt/cloud-in-a-box/deploy.sh $CLOUD_IN_A_BOX_TYPE
