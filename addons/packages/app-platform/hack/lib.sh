#!/bin/bash

NAMESPACE=app-platform-install
PACKAGE=app-platform

function addSecret {
    # expects a password file to be passed in
    USERNAME=$1
    PASSWORDFILE=$2
    tanzu secret registry add tap-registry \
          --username "$USERNAME" \
          --password $(cat "$PASSWORDFILE") \
          --server dev.registry.tanzu.vmware.com \
          --export-to-all-namespaces \
          --yes \
          --namespace "${NAMESPACE}"
}


function installAppPlatformPackage {
    tanzu package install "${PACKAGE}" -p meta-package.community.tanzu.vmware.com -v 0.1.0 -n "${NAMESPACE}"
}

function deleteAppPlatformPackage {
    tanzu package installed delete -n "${NAMESPACE}" "${PACKAGE}" -y
}

function installPrereqs {
    kapp deploy -y -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.32.0/release.yml
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
         -f ../../contour/metadata.yaml \
         -f ../../contour/1.19.1/package.yaml \
         -f ../../cert-manager/metadata.yaml \
         -f ../../cert-manager/1.6.1/package.yaml \
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
    imgpkg push -b dev.registry.tanzu.vmware.com/tap-gui/meta-package-bundle:0.1.0 -f bundle/
}
