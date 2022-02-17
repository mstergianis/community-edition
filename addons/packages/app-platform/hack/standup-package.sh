#!/bin/bash

set -euo pipefail

source ./lib.sh

addSecret dev-registry 'mstergianis@vmware.com' ~/tanzu/tanzunet_pass dev.registry.tanzu.vmware.com
addSecret prod-registry 'mstergianis@vmware.com' ~/tanzu/tanzunet_pass registry.tanzu.vmware.com
deployDevPackage
installAppPlatformPackage
