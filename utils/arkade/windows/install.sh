#!/bin/bash

# ---
# This is an isntallation for Windows users with Git Bash:
# The Git bash for Windows session must be executed as administrator
# ---
# arkade will use the /usr/local/bin/ folder, so we create it once and for all.
mkdir -p /usr/local/bin/

curl -sLS https://get.arkade.dev | sh


# --
# N.B.: It may throw some errors, like 'main: line 191: /usr/local/bin/arkade: No such file or directory', but it is still operational

arkade version
