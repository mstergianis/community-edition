#!/bin/bash

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
          --namespace app-platform-install
}


function installAppPlatformPackage {
    tanzu package install meta-package -p meta-package.community.tanzu.vmware.com -v 0.1.0 -n app-platform-install
}

function deleteAppPlatformPackage {
    tanzu package installed delete -n app-platform-install meta-package -y
}

function installPrereqs {
    kapp deploy -y -a kc -f https://github.com/vmware-tanzu/carvel-kapp-controller/releases/download/v0.32.0/release.yml
    kapp deploy -y -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.7.1/release.yml
}

function createNS {
    kubectl create ns app-platform-install --dry-run=client -o yaml | kubectl apply -f -
}

function createCluster {
    kind create cluster --name meta || echo "Lazily not recreating the cluster: meta"
}

function deleteCluster {
    kind delete cluster --name meta || echo "Lazily not deleting the non-existent cluster: meta"
}

function deployDevPackage {
    # must be in app-platform/hack dir
    kapp deploy \
         -a meta \
         -n app-platform-install \
         -f ../metadata.yaml \
         -f ../0.1.0/package.yaml \
         -f ../../contour/metadata.yaml \
         -f ../../contour/1.19.1/package.yaml \
         -y
}

function deleteDevPackage {
    kapp delete \
         -a meta \
         -n app-platform-install \
         -y
}

function pushBundle {
    # from within the app-platform/0.1.0
    imgpkg push -b dev.registry.tanzu.vmware.com/tap-gui/meta-package-bundle:0.1.0 -f bundle/
}
