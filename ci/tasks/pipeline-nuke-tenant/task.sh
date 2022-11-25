#!/usr/bin/env bash

set -euo pipefail
export OKTA_OAUTH2_CLIENT_ID=${OKTA_OAUTH2_CLIENT_ID}
export OKTA_OAUTH2_CLIENT_SECRET=${OKTA_OAUTH2_CLIENT_SECRET}
export CUSTOMER=${CUSTOMER}

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"Get auth token"${WHITE}
echo -e ${GREEN}"___"${WHITE}

export OKTA_BASIC_AUTH=$(echo -e -n $OKTA_OAUTH2_CLIENT_ID:$OKTA_OAUTH2_CLIENT_SECRET | base64 -w 0)

export API_URL="https://delivery-tenants-api.apps.us-east-1.aws.smarsh.cloud"

curl -L -s --request POST \
--url https://smarsh.okta.com/oauth2/default/v1/token \
--header 'accept: application/json' \
--header "authorization: Basic $OKTA_BASIC_AUTH" \
--header 'cache-control: no-cache' \
--header 'content-type: application/x-www-form-urlencoded' \
--data 'grant_type=client_credentials&scope=delivery_tenants_api_write' > token.json

AUTH_TOKEN=$(jq -r '.access_token' token.json)

printf "OKTA AUTH_TOKEN: " && printf "${AUTH_TOKEN}" | cut -c2-9

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"Find tenant"${WHITE}
echo -e ${GREEN}"___"${WHITE}

http_code=$(curl -LI --location --request GET "${API_URL}/tenants?page=0&size=1&customer-name=${CUSTOMER}&region=${REGION}&environment-type=${TIER}&flow-type=${FLOW_TYPE}&tenant-name=${TENANT_NAME}" -o /dev/null --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $AUTH_TOKEN" -w '%{http_code}\n' -s)
if [ ${http_code} -eq 200 ]; then
    TENANT_ID=$(curl --location --request GET "${API_URL}/tenants?page=0&size=1&customer-name=${CUSTOMER}&region=${REGION}&environment-type=${TIER}&flow-type=${FLOW_TYPE}&tenant-name=${TENANT_NAME}" \
      --header 'Content-Type: application/json' \
      --header 'Accept: application/json' \
      --header "Authorization: Bearer $AUTH_TOKEN" | jq '.[0].id')
else
  echo -e ${RED}"Error when calling tenant api"${WHITE}
  exit 1
fi

echo -e ${GREEN}"Tenant id: ${TENANT_ID}"${WHITE}

if [[ "$TENANT_ID" == null ]];
then
  echo -e ${GREEN}"Tenant id is null - exiting"${WHITE}
	exit 0
fi

result=$(curl --location --request DELETE "${API_URL}/tenants/${TENANT_ID}" --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $AUTH_TOKEN")
http_code=$(echo "$result" | jq ".apierror.status")
if [ "$http_code" == "\"OK\"" ]
then
  echo -e ${GREEN}"Tenant deleted successfully"${WHITE}
else
  echo -e ${RED}"Error when calling tenant deletion endpoint for tenant id ${TENANT_ID}.  Error code: ${http_code}"${WHITE}
  exit 1
fi