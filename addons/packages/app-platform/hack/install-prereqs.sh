#!/bin/bash

set -euo pipefail

source ./lib.sh

createNS
# installPrereqs - kapp for non-TCE clusters  -secretgen for all
