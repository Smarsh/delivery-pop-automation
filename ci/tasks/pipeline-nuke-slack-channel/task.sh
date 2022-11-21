#!/usr/bin/env bash

set -euo pipefail

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

POPLITE_CHANNEL_NAME='aws-us-west-2-poplite-prod'

curl --location --request POST "https://slack.com/api/admin.conversations.search?query=${POPLITE_CHANNEL_NAME}" \
--header "Authorization: Bearer $SLACK_EA_TENANTS_ADMIN_TOKEN" > channel.json

jq . channel.json

channel_id=$(cat channel.json | jq -r '.conversations[0].id')
channel_name=$(cat channel.json | jq -r '.conversations[0].name')

if [ "$channel_name" = "$POPLITE_CHANNEL_NAME" ]; then
    curl --location --request POST "https://slack.com/api/admin.conversations.delete?channel_id=${channel_id}" \
    --header "Authorization: Bearer $SLACK_EA_TENANTS_ADMIN_TOKEN"
else
    echo -e ${YELLOW}"The channel doesn't exist"${WHITE}
fi