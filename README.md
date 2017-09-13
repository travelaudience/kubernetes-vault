# [Draft] kubernetes-vault

Vault 0.8.2 on top of Kubernetes (backed by etcd 3.1.10).

## Table of Contents

* [Pre-Requisites](#pre-requisites)
* [Before proceeding](#before-proceeding)
* [Creating the `etcd` and `vault` namespaces](#creating-the-etcd-and-vault-namespaces)
* [Deploy `etcd`](#deploy-etcd)
  * [Deploy `etcd-operator`](#deploy-etcd-operator)
  * [Generate TLS certificates for `etcd`](#generate-tls-certificates-for-etcd)
  * [Create Kubernetes secrets for the TLS certificates](#create-kubernetes-secrets-for-the-tls-certificates)
  * [Bring up the `vault-etcd` cluster](#bring-up-the-vault-etcd-cluster)
* [Deploy `vault`](#deploy-vault)
  * [Create the `ConfigMap`](#create-the-configmap)
  * [Create the `ServiceAccount`](#create-the-serviceaccount)
  * [Create the `Deployment`](#create-the-deployment)
  * [Initializing `vault`](#initializing-vault)

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

## Creating the `etcd` and `vault` namespaces

**TODO:** Add a clear and detailed explanation.

```bash
$ kubectl create namespace etcd
namespace "etcd" created
$ kubectl create namespace vault
namespace "vault" created
```

## Deploy `etcd`

### Deploy `etcd-operator`

`etcd-operator` will be responsible for managing the etcd cluster that Vault
will use as storage backend. It will handle tasks such as periodic backups and
member recovery in disaster scenarios. `etcd-operator` and the cluster itself
will live in the `etcd` namespace.

To start with, and since RBAC is active on the cluster, one needs to setup
adequate permissions. To do this one needs  to

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
$ ./tls/create-etcd-certs.sh
2017/09/12 18:33:09 [INFO] generating a new CA key and certificate from CSR
(...)
```

### Create Kubernetes secrets for the TLS certificates

**TODO:** Add clear and detailed explanation. Make it clear that
`etcd-operator` has strict requirements regarding the secrets used for TLS.

```bash
$ ./tls/create-etcd-secrets.sh
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

## Deploy `vault`

**TODO:** Add a clear and detailed explanation.

### Create the `ConfigMap`

```bash
$ kubectl create -f vault/vault-configmap.yaml
configmap "vault" created
```

### Create the `ServiceAccount`

```bash
$ kubectl create -f vault/vault-serviceaccount.yaml
serviceaccount "vault" created
```

### Create the `Deployment`

**TODO:** Warn about (and investigate) initial handshake errors.

```bash
$ kubectl create -f vault/vault-deployment.yaml
deployment "vault" created
```

### Initializing `vault`

(Terminal 1)

```bash
$ VAULT_POD_NAME=$(kubectl get --namespace vault pod \
  | grep vault \
  | awk '{print $1}')
$ kubectl port-forward --namespace vault "${VAULT_POD_NAME}" 8200:8200
Forwarding from 127.0.0.1:8200 -> 8200
Forwarding from [::1]:8200 -> 8200
```

(Terminal 2)

```bash
$ export VAULT_ADDR='http://127.0.0.1:8200'
$ vault init
Unseal Key 1: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 2: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 3: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 4: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Unseal Key 5: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Initial Root Token: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

Vault initialized with 5 keys and a key threshold of 3. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 3 of these keys
to unseal it again.

Vault does not store the master key. Without at least 3 keys,
your vault will remain permanently sealed.
```
