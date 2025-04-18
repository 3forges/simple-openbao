#!/bin/bash


export HELM_VERSION=${HELM_VERSION:-'3.17.3'}
arkade get helm@v${HELM_VERSION}

sudo mv /home/pesto/.arkade/bin/helm /usr/local/bin/

