#!/bin/bash

source ./lib.sh

addSecret 'mstergianis@vmware.com' ~/tanzu/tanzunet_pass
deployDevPackage
installAppPlatformPackage
