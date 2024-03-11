#!/usr/bin/env bash

BASE_DIR="$(dirname $(readlink -f $0))"
source $BASE_DIR/include.sh

export INTERACTIVE=false

osism manage image clusterapi --filter 1.29

KUBERNETES_VERSION=1.29.2
IMAGE_NAME="Kubernetes CAPI $KUBERNETES_VERSION"

openstack --os-cloud admin coe cluster template create \
  --public \
  --image $(openstack --os-cloud admin image show "${IMAGE_NAME}" -c id -f value) \
  --external-network public \
  --dns-nameserver 8.8.8.8 \
  --master-lb-enabled \
  --master-flavor SCS-2V-4-20s \
  --flavor SCS-2V-4-20s \
  --network-driver calico \
  --docker-storage-driver overlay2 \
  --coe kubernetes \
  --label kube_tag=v$KUBERNETES_VERSION \
  k8s-$KUBERNETES_VERSION
