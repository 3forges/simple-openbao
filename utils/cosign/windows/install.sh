# ---
# This is an isntallation for Windows users with Git Bash:
# The Git bash for Windows session does NOT need to be executed as administrator
# ---

export COSIGN_VERSION=${COSIGN_VERSION:-'2.5.0'}
arkade get cosign@v${COSIGN_VERSION}

mv /C/Users/Utilisateur/.arkade/bin/cosign.exe /usr/local/bin/