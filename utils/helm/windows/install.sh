#!/bin/bash

# ---
# This is an isntallation for Windows users with Git Bash:
# The Git bash for Windows session does NOT need to be executed as administrator
# ---


export HELM_VERSION=${HELM_VERSION:-'3.17.3'}
arkade get helm@v${HELM_VERSION}

mv /C/Users/Utilisateur/.arkade/bin/helm.exe /usr/local/bin/