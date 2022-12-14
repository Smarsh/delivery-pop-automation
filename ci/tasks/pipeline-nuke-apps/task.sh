#!/usr/bin/env bash

set -euo pipefail

: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${REGION:?REGION env var must be provided}"
: "${CF_USERNAME:?CF_USERNAME env var must be provided}"
: "${CF_PASSWORD:?CF_PASSWORD env var must be provided}"



cf login -a "api.sys.${REGION}.aws.smarsh.cloud" -u "${CF_USERNAME}" -p "${CF_PASSWORD}" -o platform -s platform-product-services
#DRY RUN
echo "${CUSTOMER}-${TIER}"
# cf delete ehms-${CUSTOMER}-${TIER} -r -f
# cf delete iss-${CUSTOMER}-${TIER} -r -f

cf login -a "api.sys.${REGION}.aws.smarsh.cloud" -u "${CF_USERNAME}" -p "${CF_PASSWORD}" -o platform -s platform-data-services

status=$(cf apps | tail +4 | cut -d ' ' -f 1 | grep "${CUSTOMER}-${TIER}" >/dev/null 2>&1;echo $?)

if [[ $status -eq 0 ]]; then
    cf apps | tail +4 | cut -d ' ' -f 1 | grep "${CUSTOMER}-${TIER}"
    # cf apps | tail +4 | cut -d ' ' -f 1 | grep "${CUSTOMER}-${TIER}" | xargs -r -n 1 cf delete -f
fi