#!/usr/bin/env bash

set -euo pipefail

region=us-west-2

fly --target ${region}-enterprise-archive login -n enterprise-archive -c https://app-concourse.${region}.aws.smarsh.cloud -u $CONCOURSE_USERNAME -p $CONCOURSE_PASSWORD

fly --target ${region}-enterprise-archive dp -p ea-poplite-production -n