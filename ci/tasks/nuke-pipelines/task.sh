#!/usr/bin/env bash

set -euo pipefail

fly --target ${REGION}-enterprise-archive login -n enterprise-archive -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${REGION}-enterprise-archive dp -p ea-key-generation-${CUSTOMER}-${TIER} -n
fly --target ${REGION}-enterprise-archive dp -p ea-uaa-deploy-${CUSTOMER}-${TIER} -n
fly --target ${REGION}-enterprise-archive dp -p ea-create-app-tenant-${CUSTOMER}-${TIER} -n
fly --target ${REGION}-enterprise-archive dp -p ea-zookeeper-${CUSTOMER}-${TIER} -n
fly --target ${REGION}-enterprise-archive dp -p ea-e2e-sanity-${CUSTOMER}-${TIER} -n

fly --target ${REGION}-platform-product-services login -b -n platform-product-services -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${REGION}-platform-product-services dp -p ehms-${CUSTOMER}-${TIER} -n
fly --target ${REGION}-platform-product-services dp -p iss-${CUSTOMER}-${TIER} -n

fly --target ${REGION}-paasdataservices login -b -n paasdataservices -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${REGION}-paasdataservices dp -p ${CUSTOMER}-nam-archive-${TIER}-site -n
fly --target ${REGION}-paasdataservices dp -p ${CUSTOMER}-nam-archive-${TIER}-shared -n
fly --target ${REGION}-paasdataservices dp -p ${CUSTOMER}-nam-archive-${TIER}-data -n
fly --target ${REGION}-paasdataservices dp -p ${CUSTOMER}-nam-archive-${TIER}-report -n
fly --target ${REGION}-paasdataservices dp -p ${CUSTOMER}-nam-archive-${TIER}-supervision -n
fly --target ${REGION}-paasdataservices dp -p ${CUSTOMER}-nam-archive-${TIER}-msg_brokers -n

fly --target ${REGION}-sreapps login -b -n sreapps -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${REGION}-sreapps dp -p pipeline_lag_drain_script-${CUSTOMER}-${TIER} -n

fly --target ${REGION}-email-gateway login -b -n email-gateway -c https://app-concourse.${REGION}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${REGION}-email-gateway dp -p egw-${CUSTOMER}-${TIER} -n
