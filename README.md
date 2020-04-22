# Purpose

This repository contains a demo of fluxCD

# Table of Contents
1. [Create test cluster with Kind](#create-test-cluster-with-kind)
2. [Install Flux Operator](#install-flux-operator)
3. [Install Helm Operator](#install-helm-operator)
4. [Manage Sealed Secrets](#manage-sealed-secrets)

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

The Sealed Secret operator has been installed by flux and you can find the configuration file here 
[gitops/manifests/cluster-apps/sealed-secrets/release.yaml](gitops/manifests/cluster-apps/sealed-secrets/release.yaml)

## How to create a Sealed Secret

1. Firs of all we need to install the official kubeseal binary from the official repository:
https://github.com/bitnami-labs/sealed-secrets/releases
2. Create a normal secret `kubectl create secret generic my-secret --from-literal index.html=example --dry-run -o yaml > secret.yaml`
3. Create Selaed Secret object with `kubeseal < secret.yaml > sealed-secret.yaml`

