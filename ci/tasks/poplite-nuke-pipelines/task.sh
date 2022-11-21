#!/usr/bin/env bash

set -euo pipefail

region=us-west-2

fly --target ${region}-enterprise-archive login -n enterprise-archive -c https://app-concourse.${region}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${region}-enterprise-archive dp -p ea-key-generation-poplite-production -n
fly --target ${region}-enterprise-archive dp -p ea-uaa-deploy-poplite-production -n
fly --target ${region}-enterprise-archive dp -p ea-create-app-tenant-poplite-production -n
fly --target ${region}-enterprise-archive dp -p ea-zookeeper-poplite-production -n
fly --target ${region}-enterprise-archive dp -p ea-e2e-sanity-poplite-production -n

fly --target ${region}-platform-product-services login -b -n platform-product-services -c https://app-concourse.${region}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${region}-platform-product-services dp -p ehms-poplite-production -n
fly --target ${region}-platform-product-services dp -p iss-poplite-production -n

fly --target ${region}-paasdataservices login -b -n paasdataservices -c https://app-concourse.${region}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${region}-paasdataservices dp -p poplite-nam-archive-production-site -n
fly --target ${region}-paasdataservices dp -p poplite-nam-archive-production-shared -n
fly --target ${region}-paasdataservices dp -p poplite-nam-archive-production-data -n
fly --target ${region}-paasdataservices dp -p poplite-nam-archive-production-report -n
fly --target ${region}-paasdataservices dp -p poplite-nam-archive-production-supervision -n
fly --target ${region}-paasdataservices dp -p poplite-nam-archive-production-msg_brokers -n

fly --target ${region}-sreapps login -b -n sreapps -c https://app-concourse.${region}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${region}-sreapps dp -p pipeline_lag_drain_script-poplite-production -n

fly --target ${region}-email-gateway login -b -n email-gateway -c https://app-concourse.${region}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD
fly --target ${region}-email-gateway dp -p egw-poplite-production -n
