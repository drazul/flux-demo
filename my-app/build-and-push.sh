#!/bin/bash

REPOSITORY=drazul/dummy-app
VERSION=test-$(date +%s)

TAG=${REPOSITORY}:${VERSION}

docker build . -t ${TAG} --no-cache
docker push ${TAG}

