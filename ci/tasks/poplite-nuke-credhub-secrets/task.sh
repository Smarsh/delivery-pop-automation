#!/usr/bin/env bash

set -euo pipefail

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

credhub login --skip-tls-validation
# This line makes sure the delete always works.
credhub set -n /concourse/platform-delivery-services/poplite-test -t 'value' --value 'poplite'
credhub find -n poplite | grep name: | cut -c9- | xargs -I {} credhub delete -n {}