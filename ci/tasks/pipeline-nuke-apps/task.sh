#!/usr/bin/env bash

set -euo pipefail
: "${CONCOURSE_USERNAME:?CONCOURSE_USERNAME env var must be provided}"
: "${CONCOURSE_PASSWORD:?CONCOURSE_PASSWORD env var must be provided}"
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${REGION:?REGION env var must be provided}"

cf login -a api.sys.${REGION}.aws.smarsh.cloud -u ${CF_USERNAME} -p ${CF_PASSWORD} -o platform -s platform-product-services
cf delete ehms-${CUSTOMER}-${TIER} -r -f
cf delete iss-${CUSTOMER}-${TIER} -r -f

cf login -a api.sys.${REGION}.aws.smarsh.cloud -u ${CF_USERNAME} -p ${CF_PASSWORD} -o platform -s platform-data-services

status=$(cf apps | tail +4 | cut -d ' ' -f 1 | grep "${CUSTOMER}" >/dev/null 2>&1;echo $?)

if [[ $status -eq 0 ]]; then
    cf apps | tail +4 | cut -d ' ' -f 1 | grep "${CUSTOMER}" | xargs -r -n 1 cf delete -f
fi