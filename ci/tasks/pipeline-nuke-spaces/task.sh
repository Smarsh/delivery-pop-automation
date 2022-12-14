#!/usr/bin/env bash

set -euo pipefail

: "${REGION:?REGION env var must be provided}"
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${CF_USERNAME:?CF_USERNAME env var must be provided}"
: "${CF_PASSWORD:?CF_PASSWORD env var must be provided}"

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

function delete_customer_space(){
  ORG=${1}
  cf target -o ${ORG}
  echo -e ${GREEN}"Check if the customer space exists"${WHITE}
  customer_exists=$(cf spaces | grep ${CUSTOMER}-${TIER} >>/dev/null 2>&1;echo $?)
  echo -e ${GREEN}"Exists?: $customer_exists"${WHITE}
  if [ "$customer_exists" -eq  0 ]
  then
    echo -e ${GREEN}"Change target"${WHITE}
    cf target -o ${ORG} -s ${CUSTOMER}-${TIER}
    cf apps | awk '{print $1}' | xargs -I {} cf delete {} -r -f
    cf services | awk '{print $1}' | xargs -I {} cf delete-service {} -f -w
    echo -e ${GREEN}"Delete space ${CUSTOMER}-${TIER}"${WHITE}
    space_deleted=$(cf delete-space ${CUSTOMER}-${TIER} -f >>/dev/null 2>&1;echo $?)
    while [ "$space_deleted" -ne 0 ]
    do
      space_deleted=$(cf delete-space ${CUSTOMER}-${TIER} -f >>/dev/null 2>&1;echo $?)
    done
  fi

}

cf login -a "api.sys.${REGION}.aws.smarsh.cloud" -u ${CF_USERNAME} -p "\"${CF_PASSWORD}\"" -o platform -s platform-product-services
echo -e ${GREEN}"Target enterprise archive org"${WHITE}
delete_customer_space enterprise-archive
echo -e ${GREEN}"Target email-gateway org"${WHITE}
delete_customer_space email-gateway
