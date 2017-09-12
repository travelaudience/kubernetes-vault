#!/bin/bash

# TLS_DIR is the directory where this script lives.
TLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# DST_DIR is the directory where generated certificates and keys will live.
DST_DIR="${TLS_DIR}/certs"
# NAMESPACE is the namespace where to create the secrets.
NAMESPACE="etcd"

# Move to "${DST_DIR}".
pushd "${DST_DIR}" > /dev/null && \
# Create the 'etcd-peer-tls' secret.
kubectl create secret generic etcd-peer-tls \
    --namespace="${NAMESPACE}" \
    --from-file=peer-ca.crt \
    --from-file=peer.crt \
    --from-file=peer.key && \
# Create the 'etcd-server-tls' secret.
kubectl create secret generic etcd-server-tls \
    --namespace="${NAMESPACE}" \
    --from-file=server-ca.crt \
    --from-file=server.crt \
    --from-file=server.key && \
# Create the 'etcd-client-tls' secret.
kubectl create secret generic etcd-client-tls \
    --namespace="${NAMESPACE}" \
    --from-file=etcd-client-ca.crt \
    --from-file=etcd-client.crt \
    --from-file=etcd-client.key && \
# Move back to the previous directory.
popd "${DST_DIR}" > /dev/null
