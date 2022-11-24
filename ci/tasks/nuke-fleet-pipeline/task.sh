#!/usr/bin/env bash

set -euo pipefail
export CONCOURSE_USERNAME=${CONCOURSE_USERNAME}
export CONCOURSE_PASSWORD=${CONCOURSE_PASSWORD}
export CUSTOMER=${CUSTOMER}
export TIER=${TIER}
export REGION=${REGION}

fly --target ${REGION}-enterprise-archive login -n enterprise-archive -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD

fly --target ${REGION}-enterprise-archive dp -p ea-${CUSTOMER}-${TIER} -n