#!/bin/bash

# TLS_DIR is the directory where this script lives.
TLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DST_DIR is the directory where generated certificates and keys will live.
DST_DIR="${TLS_DIR}/certs"

# decrypts data from stdin into stdout
function decrypt {
    gcloud kms decrypt --plaintext-file - --ciphertext-file - --location global --keyring vault --key etcd
}

# encrypts data from stdin into stdout
function encrypt {
      gcloud kms encrypt --plaintext-file - --ciphertext-file - --location global --keyring vault --key etcd
}

# generate generates the certificates
function generate {
  # generate the CA and store the output in 'VAULT_CA_RES'.
  local VAULT_CA_RES="$(cfssl gencert -initca "../ca-csr.json")"
  # store the certificate in 'VAULT_CA_CRT'.
  local VAULT_CA_CRT="$(echo ${VAULT_CA_RES} | jq -r .cert)"
  # store the private key in 'VAULT_CA_KEY'.
  local VAULT_CA_KEY="$(echo ${VAULT_CA_RES} | jq -r .key)"

  # dump encrypted certificate to 'ca-crt.pem.kms'.
  echo "${VAULT_CA_CRT}" | encrypt > ca-crt.pem.kms
  # dump encrypted private key to 'ca-key.pem.kms'.
  echo "${VAULT_CA_KEY}" | encrypt > ca-key.pem.kms
  # dump decrypted certificate to 'ca-crt.pem'.
  cat ca-crt.pem.kms | decrypt > ca-crt.pem
  # dump encrypted private key to 'ca-crt.pem'.
  cat ca-key.pem.kms | decrypt > ca-key.pem

  for component in etcd-operator etcd-peer etcd-server vault-etcd;
  do
    # generate the component certificate and private key and store the output in 'COMPONENT_RES'.
    local COMPONENT_RES="$(cfssl gencert \
        -ca="./ca-crt.pem" \
        -ca-key="./ca-key.pem" \
        -config="../ca-config.json" \
        -profile=kubernetes-vault \
        "../${component}-csr.json")"
    # store the certificate in 'COMPONENT_CRT'.
    local COMPONENT_CRT="$(echo ${COMPONENT_RES} | jq -r .cert)"
    # store the private key in 'COMPONENT_KEY'.
    local COMPONENT_KEY="$(echo ${COMPONENT_RES} | jq -r .key)"

    # dump encrypted certificate to '${component}-crt.pem.kms'.
    echo "${COMPONENT_CRT}" | encrypt > "${component}-crt.pem.kms"
    # dump encrypted private key to '${component}-crt.pem.kms'.
    echo "${COMPONENT_KEY}" | encrypt > "${component}-key.pem.kms"
  done

  # remove 'ca-crt.pem'.
  rm -f ca-crt.pem
  # remove 'ca-key.pem'.
  rm -f ca-key.pem
}

# Create 'DST_DIR'.
mkdir -p "${DST_DIR}"
# Move to "${DST_DIR}".
pushd "${DST_DIR}" > /dev/null
# Generate the certificates.
generate
# Move back to the previous directory.
popd "${DST_DIR}" > /dev/null
