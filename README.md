# Purpose

This repository contains a demo of fluxCD.

You can find the slides [here.](slides/Continuous_Delivery_on_Kubernetes_with_GitOps.pdf)

# Table of Contents
1. [Create test cluster with Kind](#create-test-cluster-with-kind)
2. [Install Flux Operator](#install-flux-operator)
3. [Install Helm Operator](#install-helm-operator)
4. [Manage Sealed Secrets](#manage-sealed-secrets)
5. [Forward Service Port for testing](#forward-service-port-for-testing)

# Create test cluster with Kind

Kind is a very easy tool to create a testing kubernetes "cluster" in your machine.

Link: https://kind.sigs.k8s.io/docs/user/quick-start/

## Create test cluster

```bash
kind create cluster --name test-cluster
```

## Delete test cluster

```bash
kind delete cluster --name test-cluster
```

# Install Flux Operator

```bash
#!/usr/bin/env bash

set -x

helm repo add fluxcd https://charts.fluxcd.io
helm repo update

NAMESPACE=flux
CHART=fluxcd/flux
NAME=flux
VERSION=1.3.0

kubectl create namespace ${NAMESPACE} --dry-run -o yaml | kubectl apply -f -

helm upgrade \
  --install \
  --version ${VERSION} \
  --wait \
  --namespace ${NAMESPACE} \
  --set replicaCount=1 \
  --set git.url=git@github.com:drazul/flux-demo.git \
  --set git.path=gitops-manifests \
  --set git.label=sync-flux \
  --set git.user=Flux-test \
  --set git.pollInterval=1m \
  --set ssh.known_hosts="$(ssh-keyscan -H github.com)" \
  --set syncGarbageCollection.enabled=true \
  --set registry.automationInterval=5m \
  --set registry.burst=20 \
  ${NAME} \
  ${CHART} $@
```

# Install Helm Operator

```bash
#!/usr/bin/env bash

set -x

helm repo add fluxcd https://charts.fluxcd.io
helm repo update
kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

NAMESPACE=flux
CHART=fluxcd/helm-operator
NAME=helm-operator
VERSION=1.0.1

kubectl create namespace ${NAMESPACE} --dry-run -o yaml | kubectl apply -f -

helm upgrade \
  --install \
  --version ${VERSION} \
  --wait \
  --namespace ${NAMESPACE} \
  --set replicaCount=1 \
  --set createCRD=false \
  --set chartsSyncInterval=1m \
  --set workers=2 \
  --set helm.versions=v3 \
  --set git.pollInverval=5m \
  --set git.ssh.secretName=flux-git-deploy \
  --set git.ssh.known_hosts="$(ssh-keyscan -H tfs.gfk.com)" \
  ${NAME} \
  ${CHART} $@
```

# Manage Sealed Secrets

The Sealed Secret operator has been installed by flux. You can find the configuration file [here](gitops-manifests/cluster-apps/sealed-secrets/release.yaml).

## How to create a Sealed Secret

1. Firs of all we need to install the official kubeseal binary from the official repository: https://github.com/bitnami-labs/sealed-secrets/releases

2. Create a normal secret
```bash
kubectl create secret generic my-secret --from-literal index.html=example --dry-run -o yaml > secret.yaml
```

3. Seal the secret
```bash
kubeseal < secret.yaml > sealed-secret.yaml
```

## Manage certificate backup
The Sealed secret operator will rotate the encryption certificate every 30 days, and it will use the new one to seal
all new secrets. The operator will not delete the old certificates and they will be used to restore old sealed keys.

The Sealed Secret Operator will generate a new certiticate with the same name but adding a hash at the end like for example `sealed-secrets-keyff7fl`

**Note**: for more details go the [official page.](https://github.com/bitnami-labs/sealed-secrets)

## Backup certificate
We should backup all secrets on kube-system namespace with following pattern: sealed-secrets-key*
```bash
kubectl -n kube-system get secret sealed-secrets-keyff7fl -o yaml > sealed-secret-key.yaml
```

We can restore them if we add them to the cluster again
```bash
kubectl apply -f sealed-secret-key.yaml
```

## Re encrypt an existing secret
```bash
kubeseal --re-encrypt < my-sealed-secret.yaml > my-new-sealed-secret.yaml
```

# Forward Service Port for testing

In order to test if our demo apps are working we need to forward the internal cluster port to our machine. 
```
kubectl port-forward svc/my-app 8080:80
```
