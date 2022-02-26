#!/bin/bash

kind delete cluster --name ap-tce
brew uninstall vmware-tanzu/tanzu/tanzu-community-edition
rm -rf ~/.config/tanzu/tkg/unmanaged/ap-tce
brew remove kind