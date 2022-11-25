#!/usr/bin/env bash

set -euo pipefail
export CUSTOMER=${CUSTOMER}
export TIER=${TIER}

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

bosh_customer_exists=$(bosh deps --column name | grep ${CUSTOMER} >>/dev/null 2>&1;echo $?)
if [ "$bosh_customer_exists" -eq 0 ];
then
  echo -e ${GREEN}"Deleting Bosh deployments"${WHITE}
  bosh deps --column name | grep "${CUSTOMER}-*" | awk '{print $1}' | xargs -I {} bosh -n -d {} delete-deployment

  bosh_deps_deleted=$(bosh deps --column name | grep ${CUSTOMER} >>/dev/null 2>&1;echo $?)
  if [ "$bosh_deps_deleted" -eq 0 ];
  then
    echo -e ${GREEN}"List of deployments after delete"${WHITE}
    bosh deps --column name | grep ${CUSTOMER}
    exit 1
  else
    echo -e ${GREEN}"All bosh deployments deleted"${WHITE}
  fi
else
  echo -e ${GREEN}"No Bosh deployments to delete"${WHITE}
fi