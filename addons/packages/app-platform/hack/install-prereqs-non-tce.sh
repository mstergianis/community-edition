#!/bin/bash

set -euo pipefail

source ./lib.sh

createNS
installSecretGenController
installKappController
