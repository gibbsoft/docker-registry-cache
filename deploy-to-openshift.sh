#!/bin/bash
# requires docker, oc, jq

# FIXME for local dev using crc...
# OCP_REG_EXT=default-route-openshift-image-registry.apps-crc.testing

NAMESPACE=docker-registry-cache
# ensure namespace exists
oc get projects --no-headers | awk '{ print $1 }' | grep -c ${NAMESPACE} >/dev/null 2>&1 || oc new-project ${NAMESPACE}
oc project ${NAMESPACE}

if [ "$1" != "-nb" ]; then
  BUILD_ID=$(date +%s)
  OCP_REG_EXT=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')

  # registry-cache container
  docker build -t registry-cache:latest .
  docker tag registry-cache:latest ${OCP_REG_EXT}/${NAMESPACE}/registry-cache:latest
  docker tag registry-cache:latest ${OCP_REG_EXT}/${NAMESPACE}/registry-cache:${BUILD_ID}

  # get token to use to push to the registry
  oc sa get-token builder | docker login -u kubeadmin --password-stdin ${OCP_REG_EXT}

  # push
  docker push ${OCP_REG_EXT}/${NAMESPACE}/registry-cache:latest
  docker push ${OCP_REG_EXT}/${NAMESPACE}/registry-cache:${BUILD_ID}

else
  BUILD_ID=latest
fi

# process the template and created all the things
oc process -f deploy/openshift/app-template.yml -p=APPLICATION_VERSION=${BUILD_ID} | oc apply -f -
