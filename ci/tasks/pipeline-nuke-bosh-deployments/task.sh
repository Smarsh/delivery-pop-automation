#!/usr/bin/env bash

set -euo pipefail
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${SERVICE_REGION:?TIER env var must be provided}"

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

echo -e ${GREEN}"Customer: ${CUSTOMER}"${WHITE}
echo -e ${GREEN}"Tier: ${TIER}"${WHITE}
echo -e ${GREEN}"SERVICE_REGION: ${SERVICE_REGION}"${WHITE}


bosh_customer_exists=$(bosh deps --column name | grep -E  "${CUSTOMER}-${TIER}|${CUSTOMER}-${SERVICE_REGION}-archive-${TIER}" >>/dev/null 2>&1;echo $?)
if [ "$bosh_customer_exists" -eq 0 ];
then
  echo -e ${GREEN}"Deleting Bosh deployments"${WHITE}
  #DRY RUN
  bosh deps --column name | grep -E  "${CUSTOMER}-${TIER}|${CUSTOMER}-${SERVICE_REGION}-archive-${TIER}" | awk '{print $1}' 
  # bosh deps --column name | grep "${CUSTOMER}-${TIER}-*" | awk '{print $1}' | xargs -I {} bosh -n -d {} delete-deployment

  bosh_deps_deleted=$(bosh deps --column name | grep -E  "${CUSTOMER}-${TIER}|${CUSTOMER}-${SERVICE_REGION}-archive-${TIER}" >>/dev/null 2>&1;echo $?)
  if [ "$bosh_deps_deleted" -eq 0 ];
  then
    echo -e ${GREEN}"List of deployments after delete"${WHITE}
    bosh deps --column name | grep -E  "${CUSTOMER}-${TIER}|${CUSTOMER}-${SERVICE_REGION}-archive-${TIER}"
    exit 0 #DRY RUN 1->0
  else
    echo -e ${GREEN}"All bosh deployments deleted"${WHITE}
  fi
else
  echo -e ${GREEN}"No Bosh deployments to delete"${WHITE}
fi
