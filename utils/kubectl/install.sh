#!/bin/bash

export KUBECTL_VERSION=${KUBECTL_VERSION:-'1.32.2'}
arkade get kubectl@v${KUBECTL_VERSION}

sudo mv /home/pesto/.arkade/bin/kubectl /usr/local/bin/
