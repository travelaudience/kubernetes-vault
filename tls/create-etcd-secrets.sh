#!/bin/bash

# TLS_DIR is the directory where this script lives.
TLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DST_DIR is the directory where generated certificates and keys will live.
DST_DIR="${TLS_DIR}/certs"

# decrypts the file specified by '${1}' and base64-encodes it.
function decrypt_and_encode {
    gcloud kms decrypt --plaintext-file - --ciphertext-file - --location global --keyring vault --key etcd | base64
}

# Move to "${DST_DIR}".
pushd "${DST_DIR}" > /dev/null
# Create the 'etcd-operator-tls' secret.
cat <<EOF | kubectl create -f -
apiVersion: v1
data:
  etcd-client-ca.crt: $(cat ca-crt.pem.kms | decrypt_and_encode)
  etcd-client.crt: $(cat etcd-operator-crt.pem.kms | decrypt_and_encode)
  etcd-client.key: $(cat etcd-operator-key.pem.kms | decrypt_and_encode)
kind: Secret
metadata:
  name: etcd-operator-tls
  namespace: vault
type: Opaque
EOF
# Create the 'etcd-peer-tls' secret.
cat <<EOF | kubectl create -f -
apiVersion: v1
data:
  peer-ca.crt: $(cat ca-crt.pem.kms | decrypt_and_encode)
  peer.crt: $(cat etcd-peer-crt.pem.kms | decrypt_and_encode)
  peer.key: $(cat etcd-peer-key.pem.kms | decrypt_and_encode)
kind: Secret
metadata:
  name: etcd-peer-tls
  namespace: vault
type: Opaque
EOF
# Create the 'etcd-server-tls' secret.
cat <<EOF | kubectl create -f -
apiVersion: v1
data:
  server-ca.crt: $(cat ca-crt.pem.kms | decrypt_and_encode)
  server.crt: $(cat etcd-server-crt.pem.kms | decrypt_and_encode)
  server.key: $(cat etcd-server-key.pem.kms | decrypt_and_encode)
kind: Secret
metadata:
  name: etcd-server-tls
  namespace: vault
type: Opaque
EOF
# Create the 'vault-etcd-tls' secret.
cat <<EOF | kubectl create -f -
apiVersion: v1
data:
  vault-ca.crt: $(cat ca-crt.pem.kms | decrypt_and_encode)
  vault.crt: $(cat vault-crt.pem.kms | decrypt_and_encode)
  vault.key: $(cat vault-key.pem.kms | decrypt_and_encode)
kind: Secret
metadata:
  name: vault-tls
  namespace: vault
type: Opaque
EOF
# Move back to the previous directory.
popd "${DST_DIR}" > /dev/null
