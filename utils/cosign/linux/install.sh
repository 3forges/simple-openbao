#!/bin/bash


export COSIGN_VERSION=${COSIGN_VERSION:-'2.5.0'}
arkade get cosign@v${COSIGN_VERSION}

sudo mv /home/pesto/.arkade/bin/cosign /usr/local/bin/



