#!/bin/bash
set -euo pipefail

tanzu uc delete ap-tce
# rm -rf /Users/csamp/.config/tanzu/tkg/unmanaged
tanzu uc create --tkr dev.registry.tanzu.vmware.com/tap-gui/mstergianis-tkr:v1.21.5-kapp ap-tce -p 80:80 -p 443:443 -f values.yaml

while true; do
    kubeletStatus=$(kubectl get nodes -o json | jq -r .'items[0].status.conditions[] | select(.reason == "KubeletReady").status')
    echo "KubeletStatus=" $kubeletStatus
    if [ "$kubeletStatus" == "True" ]; then break; fi
    sleep 2
done

#kapp deploy -y -a sg -f https://github.com/vmware-tanzu/carvel-secretgen-controller/releases/download/v0.7.1/release.yml

#kubectl create namespace app-platform-install

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
        -f ../../fluxcd-source-controller/metadata.yaml \
        -f ../../fluxcd-source-controller/0.16.0/package.yaml \
        -y

tanzu package repository add mateo-tanzu --url index.docker.io/magonzalezoc/main:latest -n app-platform-install

tanzu package install app-platform -p app-platform.community.tanzu.vmware.com -v 0.1.0 -n app-platform-install 
