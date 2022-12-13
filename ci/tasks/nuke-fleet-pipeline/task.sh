#!/usr/bin/env bash

set -euo pipefail
: "${CONCOURSE_USERNAME:?CONCOURSE_USERNAME env var must be provided}"
: "${CONCOURSE_PASSWORD:?CONCOURSE_PASSWORD env var must be provided}"
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${REGION:?REGION env var must be provided}"

fly --target ${REGION}-enterprise-archive login -n enterprise-archive -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD

#Deleting Pipeline
echo "ea-${CUSTOMER}-${TIER}"
#DRY-RUN fly --target ${REGION}-enterprise-archive dp -p ea-${CUSTOMER}-${TIER} -n