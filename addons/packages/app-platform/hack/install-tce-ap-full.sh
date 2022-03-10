#!/bin/bash

set -euo pipefail

###
#   A fully explicit script to install app-platform on TCE without modularity
#   Assumes (almost) nothing is installed and aims to be idempotent if possible.
#
#   Assumes:
#   - docker installed v4.2.0
#   - homebrew installed (mac)
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
###

echo Install TCE
brew install vmware-tanzu/tanzu/tanzu-community-edition
/usr/local/Cellar/tanzu-community-edition/v0.10.0/libexec/configure-tce.sh

#echo Create an unmanaged TCE cluster
#tanzu unmanaged-cluster create ap-tce

echo Create an unmanaged TCE cluster with newer kapp version
tanzu uc create --tkr dev.registry.tanzu.vmware.com/tap-gui/mstergianis-tkr:v1.21.5-kapp ap-tce
exit 0
echo Install secregen-controller
kapp deploy -y -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.7.1/release.yml

echo Create namespace
kubectl create namespace app-platform-install

echo Create tanzu net registry secret to enable downloading commercial fluxcd-source-controller
#export TANZUNET_USERNAME=
#export TANZUNET_PASSWORD=
tanzu secret registry add prod-tanzu-registry \
        --username "$TANZUNET_USERNAME" \
        --password "$TANZUNET_PASSWORD" \
        --server registry.tanzu.vmware.com \
        --export-to-all-namespaces \
        --yes \
        --namespace app-platform-install

tanzu secret registry add docker-registry \
        --username "$DOCKER_USERNAME" \
        --password "$DOCKER_PASSWORD" \
        --server index.docker.io \
        --export-to-all-namespaces \
        --yes \
        --namespace app-platform-install

    kapp deploy \
         -a app-platform \
         -n app-platform-install \
         -f ../metadata.yaml \
         -f ../0.1.0/package.yaml \
         -f ../../cartographer/metadata.yaml \
         -f ../../cartographer/0.2.1/package.yaml \
         -f ../../fluxcd-source-controller/metadata.yaml \
         -f ../../fluxcd-source-controller/0.16.0/package.yaml \
         -y



echo Install app platform package
tanzu package repository add mateo-tanzu --url index.docker.io/magonzalezoc/main:latest -n app-platform-install
tanzu package install app-platform -p app-platform.community.tanzu.vmware.com -v 0.1.0 -n app-platform-install 
