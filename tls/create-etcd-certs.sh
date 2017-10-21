#!/bin/bash

# TLS_DIR is the directory where this script lives.
TLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DST_DIR is the directory where generated certificates and keys will live.
DST_DIR="${TLS_DIR}/certs"

# cleanup removes leftover '*.csr' files which we don't need.
function cleanup {
  rm -rf ./*.csr
}

# gen_ca generates the CA certificate with which all other certs are signed.
function gen_ca {
  cfssl gencert \
    -initca "../ca-csr.json" | cfssljson -bare "ca"
}

# gen_cert takes a name as a parameter and generates a certificate based on the
# "${1}.json" spec.
function gen_cert {
  cfssl gencert \
    -ca="ca.pem" \
    -ca-key="ca-key.pem" \
    -config="../ca-config.json" \
    -profile=kubernetes-vault \
    "../${1}-csr.json" | cfssljson -bare "${1}"
}

# rename_certs renames the generates certificates and keys so that it's easier
# to use them with 'etcd-operator' and 'kubectl' later on.
function rename_certs {
  # Keys have the '.key' extension.
  for file in *-key.pem;
  do
    mv "${file}" "${file/-key.pem/.key}"
  done

  # Certificates have the '.crt' extension.
  for file in *.pem;
  do
    mv "${file}" "${file/.pem/.crt}"
  done

  # We will need one CA per certificate, so we make four copies of it.
  echo "etcd-client-ca.crt" "peer-ca.crt" "server-ca.crt" "vault-etcd-ca.crt" \
    | xargs -n 1 cp ca.crt
}

# Create 'DST_DIR'.
mkdir -p "${DST_DIR}"
# Move to "${DST_DIR}".
pushd "${DST_DIR}" > /dev/null && \
# Generate the CA.
gen_ca && \
# Generate the 'etcd-client' certificate.
gen_cert etcd-client && \
# Generate the 'server' certificate.
gen_cert server && \
# Generate the 'peer' certificate.
gen_cert peer && \
# Generate the 'vault-etcd' certificate.
gen_cert vault-etcd && \
# Rename generated certificates and keys.
rename_certs && \
# Cleanup leftovers.
cleanup && \
# Move back to the previous directory.
popd "${DST_DIR}" > /dev/null
