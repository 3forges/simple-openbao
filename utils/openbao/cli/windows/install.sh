#!/bin/bash

# set -uxo pipefail
set -o errexit


unset BAO_OS
unset BAO_CPUARCH
unset BAO_VERSION
unset BAO_BIN_DWNLD_LINK
unset BAO_BIN_DWNLD_FILENAME
unset BAO_BIN_GPG_SIG_DWNLD_LINK
unset BAO_BIN_GPG_SIG_FILENAME
unset BAO_BIN_COSIGN_SIG_DWNLD_LINK
unset BAO_BIN_COSIGN_SIG_FILENAME

export BAO_OS=${BAO_OS:-'Windows'}
export BAO_CPUARCH=${BAO_CPUARCH:-'x86_64'}
export BAO_VERSION=${BAO_VERSION:-'2.2.0'}

export BAO_BIN_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/bao_${BAO_VERSION}_${BAO_OS}_${BAO_CPUARCH}.zip"
export BAO_BIN_DWNLD_FILENAME=$(echo "${BAO_BIN_DWNLD_LINK}" | awk -F '/' '{ print $NF }')

export BAO_BIN_GPG_SIG_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/bao_${BAO_VERSION}_${BAO_OS}_${BAO_CPUARCH}.zip.gpgsig"
export BAO_BIN_GPG_SIG_FILENAME=$(echo "${BAO_BIN_GPG_SIG_DWNLD_LINK}" | awk -F '/' '{ print $NF }')

export BAO_BIN_COSIGN_SIG_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/bao_${BAO_VERSION}_${BAO_OS}_${BAO_CPUARCH}.zip.sig"
export BAO_BIN_COSIGN_SIG_FILENAME=$(echo "${BAO_BIN_COSIGN_SIG_DWNLD_LINK}" | awk -F '/' '{ print $NF }')

export BAO_BIN_CERT_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/bao_${BAO_VERSION}_${BAO_OS}_${BAO_CPUARCH}.zip.pem"
export BAO_BIN_CERT_FILENAME=$(echo "${BAO_BIN_CERT_DWNLD_LINK}" | awk -F '/' '{ print $NF }')


export BAO_CHECKSUM_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/checksums-${BAO_OS}.txt"
export BAO_CHECKSUM_FILENAME=$(echo "${BAO_CHECKSUM_DWNLD_LINK}" | awk -F '/' '{ print $NF }')

export BAO_CHECKSUM_SIG_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/checksums-${BAO_OS}.txt.sig"
export BAO_CHECKSUM_SIG_FILENAME=$(echo "${BAO_CHECKSUM_SIG_DWNLD_LINK}" | awk -F '/' '{ print $NF }')

export BAO_CHECKSUM_CERT_DWNLD_LINK="https://github.com/openbao/openbao/releases/download/v${BAO_VERSION}/checksums-${BAO_OS}.txt.pem"
export BAO_CHECKSUM_CERT_FILENAME=$(echo "${BAO_CHECKSUM_CERT_DWNLD_LINK}" | awk -F '/' '{ print $NF }')


export WHERE_I_WAS=$(pwd)
export OPS_HOME=$(mktemp -d -t OPENBAO_INSTALL_XXXXX)

echo " BAO_BIN_DWNLD_LINK=[${BAO_BIN_DWNLD_LINK}]"
echo " BAO_BIN_DWNLD_FILENAME=[${BAO_BIN_DWNLD_FILENAME}]"

echo " BAO_BIN_GPG_SIG_DWNLD_LINK=[${BAO_BIN_GPG_SIG_DWNLD_LINK}]"
echo " BAO_BIN_GPG_SIG_FILENAME=[${BAO_BIN_GPG_SIG_FILENAME}]"

echo " BAO_BIN_COSIGN_SIG_DWNLD_LINK=[${BAO_BIN_COSIGN_SIG_DWNLD_LINK}]"
echo " BAO_BIN_COSIGN_SIG_FILENAME=[${BAO_BIN_COSIGN_SIG_FILENAME}]"

echo " BAO_BIN_CERT_DWNLD_LINK=[${BAO_BIN_CERT_DWNLD_LINK}]"
echo " BAO_BIN_CERT_FILENAME=[${BAO_BIN_CERT_FILENAME}]"

echo " BAO_CHECKSUM_DWNLD_LINK=[${BAO_CHECKSUM_DWNLD_LINK}]"
echo " BAO_CHECKSUM_FILENAME=[${BAO_CHECKSUM_FILENAME}]"

echo " BAO_CHECKSUM_SIG_DWNLD_LINK=[${BAO_CHECKSUM_SIG_DWNLD_LINK}]"
echo " BAO_CHECKSUM_SIG_FILENAME=[${BAO_CHECKSUM_SIG_FILENAME}]"

echo " BAO_CHECKSUM_CERT_DWNLD_LINK=[${BAO_CHECKSUM_CERT_DWNLD_LINK}]"
echo " BAO_CHECKSUM_CERT_FILENAME=[${BAO_CHECKSUM_CERT_FILENAME}]"



echo " OPS_HOME=[${OPS_HOME}]"
echo " WHERE_I_WAS=[${WHERE_I_WAS}]"


cd ${OPS_HOME}

pwd

curl -LO ${BAO_BIN_DWNLD_LINK}
ls -alh ./${BAO_BIN_DWNLD_FILENAME}

curl -LO ${BAO_BIN_GPG_SIG_DWNLD_LINK}
ls -alh ./${BAO_BIN_GPG_SIG_FILENAME}

curl -LO ${BAO_BIN_COSIGN_SIG_DWNLD_LINK}
ls -alh ./${BAO_BIN_COSIGN_SIG_FILENAME}

curl -LO ${BAO_BIN_CERT_DWNLD_LINK}
ls -alh ./${BAO_BIN_CERT_FILENAME}

curl -LO ${BAO_CHECKSUM_DWNLD_LINK}
ls -alh ./${BAO_CHECKSUM_FILENAME}

curl -LO ${BAO_CHECKSUM_SIG_DWNLD_LINK}
ls -alh ./${BAO_CHECKSUM_SIG_FILENAME}

curl -LO ${BAO_CHECKSUM_CERT_DWNLD_LINK}
ls -alh ./${BAO_CHECKSUM_CERT_FILENAME}









############
## Cosign CHECKSUMS signature verifications

cosign verify-blob \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/openbao/openbao/.github/workflows/release.yml@refs/tags/v${BAO_VERSION} \
  --certificate=./${BAO_CHECKSUM_CERT_FILENAME} \
  --signature=./${BAO_CHECKSUM_SIG_FILENAME} \
  ./${BAO_CHECKSUM_FILENAME}

############
## CHECKSUMS verifications

cat ./${BAO_CHECKSUM_FILENAME} | grep "${BAO_BIN_DWNLD_FILENAME}" | grep -v 'json' | sha256sum -c -

############
## Cosign tar.gz signature verifications
cosign verify-blob \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
  --certificate-identity=https://github.com/openbao/openbao/.github/workflows/release.yml@refs/tags/v${BAO_VERSION} \
  --certificate=./${BAO_BIN_CERT_FILENAME} \
  --signature=./${BAO_BIN_COSIGN_SIG_FILENAME} \
  ./${BAO_BIN_DWNLD_FILENAME}

mkdir -p ./deflated

# tar -xvzf ./${BAO_BIN_DWNLD_FILENAME} -C ./deflated
unzip ./${BAO_BIN_DWNLD_FILENAME} -d ./deflated

ls -alh ./deflated/
ls -alh ./deflated/bao
./deflated/bao --version

runComamndRequiringbeingAdmin () {
mkdir -p /usr/bin/bao-${BAO_VERSION}/
mv ./deflated/bao /usr/bin/bao-${BAO_VERSION}/
mv ./deflated/LICENSE  /usr/bin/bao-${BAO_VERSION}/
mv ./deflated/*.md  /usr/bin/bao-${BAO_VERSION}/

ln -s /usr/bin/bao-${BAO_VERSION}/bao /usr/bin/bao
}

runComamndRequiringbeingAdmin


bao --version
cd ${WHERE_I_WAS}


