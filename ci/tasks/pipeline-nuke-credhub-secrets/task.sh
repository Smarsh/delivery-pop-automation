#!/usr/bin/env bash

set -euo pipefail
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${SERVICE_REGION:?SERVICE_REGION env var must be provided}"

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

credhub login --skip-tls-validation
# This line makes sure the delete always works.
credhub set -n /concourse/platform-delivery-services/${CUSTOMER}-${SERVICE_REGION}-archive-${TIER}-dummy -t 'value' --value 'dummy'
credhub find -n ${CUSTOMER}-${SERVICE_REGION}-archive-${TIER} | grep name: | cut -c9- | xargs -I {} credhub delete -n {}

credhub set -n /concourse/platform-delivery-services/${CUSTOMER}-${TIER}-dummy -t 'value' --value 'dummy'
credhub find -n ${CUSTOMER}-${TIER} | grep name: | cut -c9- | xargs -I {} credhub delete -n {}

credhub set -n /concourse/platform-delivery-services/${CUSTOMER}/${TIER}-dummy -t 'value' --value 'dummy'
credhub find -n ${CUSTOMER}/${TIER} | grep name: | cut -c9- | xargs -I {} credhub delete -n {}
