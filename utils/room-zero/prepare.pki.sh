#!/bin/bash
# set -uxo pipefail
set -o errexit

export PKI_PREPARATION_HOME=${PKI_PREPARATION_HOME:-"${HOME}/.pesto.pki"}

if [ -d ${PKI_PREPARATION_HOME} ]; then
  rm -fr ${PKI_PREPARATION_HOME}
fi;
mkdir -p ${PKI_PREPARATION_HOME}

echo " PKI_PREPARATION_HOME = [${PKI_PREPARATION_HOME}] "

export OPENBAO_SERVICE_FQDN=${OPENBAO_SERVICE_FQDN:-"openbao.pesto.io"}

export OPENBAO_CERT_CRT_FILEPATH=${PKI_PREPARATION_HOME}/$OPENBAO_SERVICE_FQDN/${OPENBAO_SERVICE_FQDN}.tls.key
export OPENBAO_CERT_KEY_FILEPATH=${PKI_PREPARATION_HOME}/$OPENBAO_SERVICE_FQDN/$OPENBAO_SERVICE_FQDN.tls.crt
export OPENBAO_CERT_CSR_FILEPATH=${PKI_PREPARATION_HOME}/$OPENBAO_SERVICE_FQDN/${OPENBAO_SERVICE_FQDN}.csr
export OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH=${PKI_PREPARATION_HOME}/$OPENBAO_SERVICE_FQDN/$OPENBAO_SERVICE_FQDN.v3.ext

echo " OPENBAO_CERT_CRT_FILEPATH = [${OPENBAO_CERT_CRT_FILEPATH}] "
echo " OPENBAO_CERT_KEY_FILEPATH = [${OPENBAO_CERT_KEY_FILEPATH}] "
echo " OPENBAO_CERT_CSR_FILEPATH = [${OPENBAO_CERT_CSR_FILEPATH}] "
echo " OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH = [${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH}] "


setUpVaultBAOAlias () {
# ---
# requires to sudo
export BAO_CLI_EXECUTABLE_LOCATION=$(which bao)
sudo ln -s ${BAO_CLI_EXECUTABLE_LOCATION} /usr/bin/vault
vault --version

}
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
#  >>> --- <<< CA CERT >>> --- <<< 
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# 

# --- <<<>>>
# Generate the Certificate Authority Private Key
export PESTO_CA_NAME=${PESTO_CA_NAME:-"Pestoplatform-RootCA"}

export PESTO_CA_PASSPHRASE=${PESTO_CA_PASSPHRASE:-'In that pleasant district of merry England which is watered by the river Don, there extended in ancient times a large forest, covering the greater part of the beautiful hills and valleys which lie between Sheffield and the pleasant town of Doncaster.'}

mkdir ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME

# -
# AES encrypted private key
openssl genrsa -passout pass:"$PESTO_CA_PASSPHRASE" -aes256 -out ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.key 4096


saveCAPrivateKeyAndPassphraseToVault () {

export PKI_PREPARATION_HOME=${PKI_PREPARATION_HOME:-"${HOME}/.pesto.pki"}
export PESTO_CA_NAME=${PESTO_CA_NAME:-"Pestoplatform-RootCA"}
export PESTO_CA_PASSPHRASE='In that pleasant district of merry England which is watered by the river Don, there extended in ancient times a large forest, covering the greater part of the beautiful hills and valleys which lie between Sheffield and the pleasant town of Doncaster.'

ls -alh ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.key

export OPENBAO_SERVICE_FQDN=${OPENBAO_SERVICE_FQDN:-"openbao.pesto.io"}

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default

export PESTO_CA_KEY_ENCODED=$(cat ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.key | base64 | tr -d '\n')
vault kv put -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert private-key="${PESTO_CA_KEY_ENCODED}"
export PESTO_CA_PASSPHRASE_ENCODED=$(echo "$PESTO_CA_PASSPHRASE" | base64 | tr -d '\n')
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert private-key-passphrase="${PESTO_CA_PASSPHRASE_ENCODED}"

}


# --- <<<>>>
# Generate the Certificate Authority TLS Certificate (and save it to vault)
# 1826 days = 5 years
# 
export PESTO_CA_SERVICE_FQDN=${PESTO_CA_SERVICE_FQDN:-"pestoplaform-ca.pesto.io"}
# # (not sure yet I should set alt names for CA Cert)
# # openssl req -x509 -new -nodes -key ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.key -passin pass:"$PESTO_CA_PASSPHRASE" -sha256 -days 1826 -out ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.crt -subj "/CN=${PESTO_CA_NAME}$/C=FR/ST=Chamalieres/L=Chamalieres/O=${PESTO_CA_SERVICE_FQDN}" -addext "subjectAltName = DNS:${PESTO_CA_SERVICE_FQDN}"

# ---
# export PESTO_CA_PASSPHRASE_TO_DECODE=$(vault kv get -field=private-key-passphrase -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
# export PESTO_CA_PASSPHRASE=$(echo "${PESTO_CA_PASSPHRASE_TO_DECODE}" | base64 -d)
retrieveCAcertPassphraseFromVault () {

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default

export PESTO_CA_PASSPHRASE_TO_DECODE=$(vault kv get -field=private-key-passphrase -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
export PESTO_CA_PASSPHRASE=$(echo "${PESTO_CA_PASSPHRASE_TO_DECODE}" | base64 -d)

}

# --
# I do not retrieve the PESTO_CA_PASSPHRASE and 
# the CA Cert Private Key from the vault: because
# I am in the process of generating the CA Cert, in
# order to then, generate a TLS Certificate for the
# OpenBAO Vault service provisioning: So at this 
# time, the OpenBAO Vault is not yet available.
openssl req -x509 -new -nodes -key ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.key -passin pass:"$PESTO_CA_PASSPHRASE" -sha256 -days 1826 -out ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.crt -subj "/CN=${PESTO_CA_NAME}$/C=FR/ST=Chamalieres/L=Chamalieres/O=${PESTO_CA_SERVICE_FQDN}"

saveCACertToVault () {
export PKI_PREPARATION_HOME=${PKI_PREPARATION_HOME:-"${HOME}/.pesto.pki"}
export PESTO_CA_NAME=${PESTO_CA_NAME:-"Pestoplatform-RootCA"}

ls -alh ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.crt
export PESTO_CA_CERT_ENCODED=$(cat ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.crt | base64 | tr -d '\n')

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default


vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert ca-crt="${PESTO_CA_CERT_ENCODED}"
}


# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
#   <<< RETRIEVE CA FROM VAULT >>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# 
retrieveAllCASecretsFromVault () {

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default

# ---
# Re-read the stored CA Key, CA key passphrase, and CA Cert
export PESTO_CA_KEY_BASE64_ENCODED=$(vault kv get -field=private-key -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
echo "${PESTO_CA_KEY_BASE64_ENCODED}" | base64 -d | tee ./pestoplatform.ca.key

export PESTO_CA_CERT_BASE64_ENCODED=$(vault kv get -field=ca-crt -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
echo "${PESTO_CA_KEY_BASE64_ENCODED}" | base64 -d | tee ./pestoplatform.ca.crt

export PESTO_CA_PASSPHRASE_TO_DECODE=$(vault kv get -field=private-key-passphrase -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
export PESTO_CA_PASSPHRASE=$(echo "${PESTO_CA_PASSPHRASE_TO_DECODE}" | base64 -d)

}

# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# >>> To trust The CA signed certifcates in an OS:
# 

trustCAforDebianDerivedDistribs() {

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default

export PESTO_CA_CERT_BASE64_ENCODED=$(vault kv get -field=ca-crt -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
echo "${PESTO_CA_KEY_BASE64_ENCODED}" | base64 -d | tee ./pestoplatform.ca.crt

sudo apt-get install -y ca-certificates
sudo cp ./pestoplatform.ca.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
}

trustCAforRedhatDistribs() {

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default

export PESTO_CA_CERT_BASE64_ENCODED=$(vault kv get -field=ca-crt -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
echo "${PESTO_CA_KEY_BASE64_ENCODED}" | base64 -d | tee ./pestoplatform.ca.crt

sudo cp ./pestoplatform.ca.crt /etc/pki/ca-trust/source/anchors/pestoplatform.ca.crt
sudo update-ca-trust
}

# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
#  >>> - <<< OpenBAO CERT >>> - <<< 
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# 

# 1./ Generate the TLS Certificate Signing Request for OpenBAO
export OPENBAO_SERVICE_FQDN=${OPENBAO_SERVICE_FQDN:-"openbao.pesto.io"}
openssl req -new -nodes -out ${OPENBAO_CERT_CSR_FILEPATH} -newkey rsa:4096 -keyout ${OPENBAO_CERT_CRT_FILEPATH} -subj "/CN=${OPENBAO_SERVICE_FQDN}/C=FR/ST=Chamalieres/L=Chamalieres/O=${OPENBAO_SERVICE_FQDN}"

# 2./ Generate the v3 ext file for SAN properties for OpenBAO
export OPENBAO_SERVICE_IP_ADDR=${OPENBAO_SERVICE_IP_ADDR:-"192.168.1.16"}
export OPENBAO_SERVICE_IP_ADDR_2=${OPENBAO_SERVICE_IP_ADDR_2:-"192.168.1.18"}

cat > ${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH} << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${OPENBAO_SERVICE_FQDN}
DNS.2 = openbao.local
IP.1 = ${OPENBAO_SERVICE_IP_ADDR}
IP.2 = ${OPENBAO_SERVICE_IP_ADDR_2}
EOF

# 3./ Generate the OpenBAO TLS Cert, signed with the CA Cert Key (no private key is generated, since it was already generated at CSR time generation):

openssl x509 -req -passin pass:"$PESTO_CA_PASSPHRASE" -in ${OPENBAO_CERT_CSR_FILEPATH} -CA ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.crt -CAkey ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.key -CAcreateserial -out ${OPENBAO_CERT_KEY_FILEPATH} -days 730 -sha256 -extfile ${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH}

# retrieveAllCASecretsFromVault

# files generated are:

ls -alh ${OPENBAO_CERT_CRT_FILEPATH}
ls -alh ${OPENBAO_CERT_KEY_FILEPATH}
ls -alh ${OPENBAO_CERT_CSR_FILEPATH}
ls -alh ${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH}

saveOpenBaoTLSCertSecretsToOpenBaoVault () {

ls -alh ${OPENBAO_CERT_CRT_FILEPATH}
ls -alh ${OPENBAO_CERT_KEY_FILEPATH}
ls -alh ${OPENBAO_CERT_CSR_FILEPATH}
ls -alh ${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH}
# - 
# and finally save the OpenBAO tls cert and key, also the CSR and the v3 ext file for SAN Properties
export OPENBAO_CERT_KEY=$(cat ${OPENBAO_CERT_CRT_FILEPATH} | base64 | tr -d '\n')
# cat tls.crt | base64 | tr -d '\n' | base64 -d
export OPENBAO_CERT_PUB=$(cat ${OPENBAO_CERT_KEY_FILEPATH} | base64 | tr -d '\n')

export OPENBAO_CERT_CSR=$(cat ${OPENBAO_CERT_CSR_FILEPATH} | base64 | tr -d '\n')

export OPENBAO_CERT_SAN_PROPS_FILE=$(cat ${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH} | base64 | tr -d '\n')

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default

# ---
# Write the secrets to the vault
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/openbao-cert/openbao-tls-cert tls-key="${OPENBAO_CERT_KEY}"
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/openbao-cert/openbao-tls-cert tls-crt="${OPENBAO_CERT_PUB}"
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/openbao-cert/openbao-tls-cert csr="${OPENBAO_CERT_CSR}"
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/openbao-cert/openbao-tls-cert san-properties-v3-ext-file="${OPENBAO_CERT_SAN_PROPS_FILE}"


}

# ---
# FINALLY let's verify the OpenBAO generated TLS Cert, with the 
# CA Cert
openssl verify -verbose -CAfile ${PKI_PREPARATION_HOME}/$PESTO_CA_NAME/$PESTO_CA_NAME.crt ${OPENBAO_CERT_KEY_FILEPATH}



exit 0

# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
#  >>> --- <<< PG CERT >>> --- <<< 
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>
# After OpenBAO service is 
# provisioned and available, when 
# generating any TLS cert for any 
# pesto stack service, we will 
# retrieve the Root CA from the
# OpenBAO Vault 


export PGSQL_SERVICE_FQDN=${PGSQL_SERVICE_FQDN:-'postgres.pesto.io'}


# 1./ Generate the TLS Certificate Signing Request for Postgres DB Service

openssl req -new -nodes -out ./${PGSQL_SERVICE_FQDN}.csr -newkey rsa:4096 -keyout ./postgres.tls.key -subj "/CN=${PGSQL_SERVICE_FQDN}/C=FR/ST=Chamalieres/L=Chamalieres/O=${PGSQL_SERVICE_FQDN}"

# 2./ Generate the v3 ext file for SAN properties for Postgres DB Service
export PGSQL_SERVICE_IP_ADDR="192.168.1.16"
export PGSQL_SERVICE_IP_ADDR_2="192.168.1.17"

cat > ./$PGSQL_SERVICE_FQDN.v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${PGSQL_SERVICE_FQDN}
DNS.2 = postgres.local
IP.1 = ${PGSQL_SERVICE_IP_ADDR}
IP.2 = ${PGSQL_SERVICE_IP_ADDR_2}
EOF

# 3./ Generate the Postgres DB TLS Cert, signed with the CA Cert Key (no private key is generated, since it was already generated at CSR time generation):

export VAULT_ADDR="https://${OPENBAO_SERVICE_FQDN}"
export BAO_ADDR="${VAULT_ADDR}"
# ---
# https://openbao.org/docs/auth/jwt/oidc-providers/keycloak/
vault login -method=oidc -path=keycloak role=pesto-default


export PESTO_CA_KEY_BASE64_ENCODED=$(vault kv get -field=private-key -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
echo "${PESTO_CA_KEY_BASE64_ENCODED}" | base64 -d | tee ./pestoplatform.ca.key

export PESTO_CA_CERT_BASE64_ENCODED=$(vault kv get -field=ca-crt -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
echo "${PESTO_CA_CERT_BASE64_ENCODED}" | base64 -d | tee ./pestoplatform.ca.crt

export PESTO_CA_PASSPHRASE_TO_DECODE=$(vault kv get -field=private-key-passphrase -mount=apps/pesto/kv/nonprod /pesto/pki/ca-cert)
export PESTO_CA_PASSPHRASE=$(echo "${PESTO_CA_PASSPHRASE_TO_DECODE}" | base64 -d)


openssl x509 -req -passin pass:"$PESTO_CA_PASSPHRASE" -in ./${PGSQL_SERVICE_FQDN}.csr -CA ./pestoplatform.ca.crt -CAkey ./pestoplatform.ca.key -CAcreateserial -out ./${PGSQL_SERVICE_FQDN}.tls.crt -days 730 -sha256 -extfile ./$PGSQL_SERVICE_FQDN.v3.ext

# files generated are:

ls -alh ./${PGSQL_SERVICE_FQDN}.tls.key
ls -alh ./${PGSQL_SERVICE_FQDN}.tls.crt
ls -alh ./${PGSQL_SERVICE_FQDN}.csr
ls -alh ./${PGSQL_SERVICE_FQDN}.v3.ext

# - 
# And finally save to OpenAO Vault, the Postgres DB tls cert and key, also the CSR and the v3 ext file for SAN Properties
export PGSQL_CERT_KEY=$(cat ./${PGSQL_SERVICE_FQDN}.tls.key | base64 | tr -d '\n')
# cat tls.crt | base64 | tr -d '\n' | base64 -d
export PGSQL_CERT_PUB=$(cat ./${PGSQL_SERVICE_FQDN}.tls.crt | base64 | tr -d '\n')

export PGSQL_CERT_CSR=$(cat ./${PGSQL_SERVICE_FQDN}.csr | base64 | tr -d '\n')

export PGSQL_CERT_SAN_PROPS_FILE=$(cat ${OPENBAO_CERT_CSR_V3_SAN_PROPS_FILEPATH} | base64 | tr -d '\n')

# ---
# Write the secrets to the vault
vault kv put -mount=apps/pesto/kv/nonprod /pesto/pki/postgres-cert/postgres-tls-cert tls-key="${PGSQL_CERT_KEY}"
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/postgres-cert/postgres-tls-cert tls-crt="${PGSQL_CERT_PUB}"
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/postgres-cert/postgres-tls-cert csr="${PGSQL_CERT_CSR}"
vault kv patch -mount=apps/pesto/kv/nonprod /pesto/pki/postgres-cert/postgres-tls-cert san-properties-v3-ext-file="${PGSQL_CERT_SAN_PROPS_FILE}"

# ---
# FINALLY let's verify the Postgres DB generated TLS Cert, with the 
# CA Cert
openssl verify -verbose -CAfile ./pestoplatform.ca.crt ./postgres.tls.crt
