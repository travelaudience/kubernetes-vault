#!/bin/bash

# TLS_DIR is the directory where this script lives.
TLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DST_DIR is the directory where generated certificates and keys will live.
DST_DIR="${TLS_DIR}/certs"

# Move to "${DST_DIR}".
pushd "${DST_DIR}" > /dev/null && \
# Create the 'etcd-peer-tls' secret.
kubectl create secret generic etcd-peer-tls \
    --namespace=etcd \
    --from-file=peer-ca.crt \
    --from-file=peer.crt \
    --from-file=peer.key && \
# Create the 'etcd-server-tls' secret.
kubectl create secret generic etcd-server-tls \
    --namespace=etcd \
    --from-file=server-ca.crt \
    --from-file=server.crt \
    --from-file=server.key && \
# Create the 'etcd-client-tls' secret.
kubectl create secret generic etcd-client-tls \
    --namespace=etcd \
    --from-file=etcd-client-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key && \
# Create the 'etcd-vault-tls' secret.
kubectl create secret generic vault-etcd-tls \
    --namespace=vault \
    --from-file=vault-etcd-ca.crt \
    --from-file=vault-etcd.crt \
    --from-file=vault-etcd.key && \
# Move back to the previous directory.
popd "${DST_DIR}" > /dev/null
