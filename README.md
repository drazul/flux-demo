# Purpose

This repository contains a demo of fluxCD

# How to install flux

## Install flux operator

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

