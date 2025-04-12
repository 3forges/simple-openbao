#!/bin/bash

export ARKADE_VERSION=${ARKADE_VERSION:-'0.11.38'}

export ARKADE_OS=${ARKADE_OS:-'linux'}
export ARKADE_CPUARCH=${ARKADE_CPUARCH:-'amd64'}


# export ARKADE_DWNLD_LINK=${ARKADE_DWNLD_LINK:-"https://github.com/kubernetes-sigs/arkade/releases/download/v${ARKADE_VERSION}/arkade_${ARKADE_VERSION}_${ARKADE_OS}_${ARKADE_CPUARCH}.tar.gz"}

export ARKADE_DWNLD_LINK=${ARKADE_DWNLD_LINK:-"https://github.com/alexellis/arkade/releases/download/${ARKADE_VERSION}/arkade"}

if [ -d /tmp/ARKADE/${ARKADE_VERSION}/deflated/ ]; then
  rm -fr /tmp/ARKADE/${ARKADE_VERSION}/deflated/
fi;
mkdir -p /tmp/ARKADE/${ARKADE_VERSION}/deflated/

export WHERE_I_WAS=$(pwd)

cd /tmp/ARKADE/${ARKADE_VERSION}/deflated/

curl -LO ${ARKADE_DWNLD_LINK}


ls -alh .


sudo mkdir -p /usr/bin/arkade-${ARKADE_VERSION}/
sudo mv ./arkade /usr/bin/arkade-${ARKADE_VERSION}/

sudo chmod a+x /usr/bin/arkade-${ARKADE_VERSION}/arkade

sudo ln -s /usr/bin/arkade-${ARKADE_VERSION}/arkade /usr/bin/arkade

cd ${WHERE_I_WAS}
