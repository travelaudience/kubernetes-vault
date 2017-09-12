# [Draft] kubernetes-vault

Vault 0.8.2 on top of Kubernetes (backed by etcd 3.1.10).

## Table of Contents

* [Pre-Requisites](#pre-requisites)
* [Before proceeding](#before-proceeding)
* [Deploy `etcd`](#deploy-etcd)
  * [Deploy `etcd-operator`](#deploy-etcd-operator)
  * [Generate TLS certificates for `etcd`](#generate-tls-certificates-for-etcd)
  * [Create Kubernetes secrets for the TLS certificates](#create-kubernetes-secrets-for-the-tls-certificates)
  * [Bring up the `vault-etcd` cluster](#bring-up-the-vault-etcd-cluster)

## Pre-Requisites

* A working GKE cluster running Kubernetes v1.7.5 with legacy authorization
  _disabled_.
* A working installation of `gcloud` configured to access the target Google
  Cloud Platform project.
* A working installation of `kubectl` configured to access the target cluster.
* A working installation of [`cfssl`](https://github.com/cloudflare/cfssl).
  * This, in turn, requires a working installation of Go 1.6+.

## Before proceeding

**ATTENTION:** Disabling legacy authorization on the cluster means that
_Role-Based Access Control_
([RBAC](https://kubernetes.io/docs/admin/authorization/rbac/)) is enabled. RBAC
is the new way to manage permissions in Kubernetes 1.6+. Reading the RBAC
documentation and understanding the differences between RBAC and legacy
authorization is strongly encouraged.

**ATTENTION:** One must grant themselves the `cluster-admin` role **manually**
before proceeding. This is due to a known issue with RBAC on GKE. To do that
one must retrieve their identity using `gcloud` by running

```bash
$ MY_GCLOUD_USER=$(gcloud info \
  | grep Account \
  | awk -F'[][]' '{print $2}')
```

and then create a `ClusterRoleBinding` by running

```bash
$ kubectl create clusterrolebinding \
  my-cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=${MY_GCLOUD_USER}
```

## Deploy `etcd`

### Deploy `etcd-operator`

`etcd-operator` will be responsible for managing the etcd cluster that Vault
will use as storage backend. It will handle tasks such as periodic backups and
member recovery in disaster scenarios.

Both `etcd-operator` and the cluster itself will will live in the `etcd`
namespace. One should thus start by creating this namespace:

```bash
$ kubectl create -f ./etcd-namespace.yaml
namespace "etcd-operator" created
```

Then, and since RBAC is active on the cluster, one needs to setup adequate
permissions. To do this one needs to

* Create a `ClusterRole` specifying a list of permissions;
* Create a dedicated `ServiceAccount` for `etcd-operator`;
* Create a `CluserRoleBinding` that will grant these permissions to the service
  account.

```bash
$ kubectl create -f ./etcd-operator/etcd-operator-clusterrole.yaml
clusterrole "etcd-operator" created
```

```bash
$ kubectl create -f ./etcd-operator/etcd-operator-serviceaccount.yaml
serviceaccount "etcd-operator" created
```

```bash
$ kubectl create -f ./etcd-operator/etcd-operator-clusterrolebinding.yaml
clusterrolebinding "etcd-operator" created
```

One is now ready to deploy `etcd-operator` itself:

```bash
$ kubectl create -f ./etcd-operator/etcd-operator-deployment.yaml
deployment "etcd-operator" created
```

### Generate TLS certificates for `etcd`

**TODO:** Add clear and detailed explanation. Make it clear that this CA is
different from the final CA we want to establish, and that it serves a
different purpose.

```bash
$ ./tls/gen-certs.sh
2017/09/12 18:33:09 [INFO] generating a new CA key and certificate from CSR
(...)
```

### Create Kubernetes secrets for the TLS certificates

**TODO:** Add clear and detailed explanation. Make it clear that
`etcd-operator` has strict requirements regarding the secrets used for TLS.

```bash
$ ./tls/gen-secrets.sh
secret "etcd-peer-tls" created
secret "etcd-server-tls" created
secret "etcd-client-tls" created
```

### Bring up the `vault-etcd` cluster

**TODO:** Add clear and detailed explanation. Make it clear that the cluster is
created as a CR rather than a `Deployment` or `ReplicaSet`.

```bash
$ kubectl create -f etcd/vault-etcd-etcdcluster.yaml
etcdcluster "etcd-vault" created
```