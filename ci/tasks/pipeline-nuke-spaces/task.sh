#!/usr/bin/env bash

set -euo pipefail

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

function delete_customer_space(){
  ORG=${1}
  cf target -o ${ORG}
  echo -e ${GREEN}"Check if the customer-production space exists"${WHITE}
  customer_exists=$(cf spaces | grep ${CUSTOMER}-production >>/dev/null 2>&1;echo $?)
  echo -e ${GREEN}"Production: $customer_exists"${WHITE}
  if [ "$customer_exists" -eq  0 ]
  then
    echo -e ${GREEN}"Change target"${WHITE}
    cf target -o ${ORG} -s ${CUSTOMER}-production

    echo -e ${GREEN}"Delete space"${WHITE}
    space_deleted=$(cf delete-space ${CUSTOMER}-production -f >>/dev/null 2>&1;echo $?)
    while [ "$space_deleted" -ne 0 ]
    do
      space_deleted=$(cf delete-space ${CUSTOMER}-production -f >>/dev/null 2>&1;echo $?)
    done
  fi

}

cf login -a api.sys.${REGION}.aws.smarsh.cloud -u ${CF_USERNAME} -p ${CF_PASSWORD} -o platform -s platform-product-services
echo -e ${GREEN}"Target enterprise archive org"${WHITE}
delete_customer_space enterprise-archive
echo -e ${GREEN}"Target email-gateway org"${WHITE}
delete_customer_space email-gateway