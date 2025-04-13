#!/bin/bash

export KND_CLOUD_PROVIDER_VERSION=${KND_CLOUD_PROVIDER_VERSION:-'0.6.0'}

export KND_CLOUD_PROVIDER_OS=${KND_CLOUD_PROVIDER_OS:-'linux'}
export KND_CLOUD_PROVIDER_CPUARCH=${KND_CLOUD_PROVIDER_CPUARCH:-'amd64'}


export KND_CLOUD_PROVIDER_DWNLD_LINK=${KND_CLOUD_PROVIDER_DWNLD_LINK:-"https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/v${KND_CLOUD_PROVIDER_VERSION}/cloud-provider-kind_${KND_CLOUD_PROVIDER_VERSION}_${KND_CLOUD_PROVIDER_OS}_${KND_CLOUD_PROVIDER_CPUARCH}.tar.gz"}

export OPERATOR_USER=$(whoami)

if [ -d /opt/cloud_provider_kind/run ]; then
  sudo rm -fr /opt/cloud_provider_kind
fi;

sudo mkdir -p /opt/cloud_provider_kind/run

sudo chown -R ${OPERATOR_USER}:${OPERATOR_USER} /opt/cloud_provider_kind

git clone git@github.com:kubernetes-sigs/cloud-provider-kind.git /opt/cloud_provider_kind/run

export WHERE_I_WAS=$(pwd)

cd /opt/cloud_provider_kind/run
git checkout v${KND_CLOUD_PROVIDER_VERSION}


# cat <<EOF >./docker-compose.yml
# 
# EOF

NET_MODE=kind docker compose up -d

cd ${WHERE_I_WAS}