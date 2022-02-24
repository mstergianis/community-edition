#!/bin/bash

NAMESPACE=app-platform-install
PACKAGE=app-platform

function addSecret {
    # expects a password file to be passed in
    SECRET_NAME=$1
    USERNAME=$2
    PASSWORDFILE=$3
    SERVER=$4
    tanzu secret registry add "$SECRET_NAME" \
          --username "$USERNAME" \
          --password $(cat "$PASSWORDFILE") \
          --server "$SERVER" \
          --export-to-all-namespaces \
          --yes \
          --namespace "${NAMESPACE}"
}


function installAppPlatformPackage {
    tanzu package install "${PACKAGE}" -p app-platform.community.tanzu.vmware.com -v 0.1.0 -n "${NAMESPACE}"
}

function deleteAppPlatformPackage {
    tanzu package installed delete -n "${NAMESPACE}" "${PACKAGE}" -y
}

function installKappController {
    kapp deploy -y -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.32.0/release.yml
}

function installSecretGenController {
    kapp deploy -y -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.7.1/release.yml
}

function createNS {
    kubectl create ns "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
}

function createCluster {
    kind create cluster --name "${PACKAGE}" || echo "Lazily not recreating the cluster: ${PACKAGE}"
}

function deleteCluster {
    kind delete cluster --name "${PACKAGE}" || echo "Lazily not deleting the non-existent cluster: ${PACKAGE}"
}

function deployDevPackage {
    # must be in app-platform/hack dir
    kapp deploy \
         -a "${PACKAGE}" \
         -n "${NAMESPACE}" \
         -f ../metadata.yaml \
         -f ../0.1.0/package.yaml \
         -f ../../cartographer/metadata.yaml \
         -f ../../cartographer/0.2.1/package.yaml \
         -f ../../fluxcd-source-controller/metadata.yaml \
         -f ../../fluxcd-source-controller/0.16.0/package.yaml \
         -y
}

function deleteDevPackage {
    kapp delete \
         -a "${PACKAGE}" \
         -n "${NAMESPACE}" \
         -y
}

function pushBundle {
    # from within the app-platform/0.1.0
    # imgpkg push -b dev.registry.tanzu.vmware.com/tap-gui/meta-package-bundle:0.1.0 -f bundle/
    imgpkg push -b index.docker.io/csamp/app-platform-package-bundle:0.1.0 -f bundle/
}
