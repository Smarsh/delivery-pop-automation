#!/usr/bin/env bash

set -euo pipefail

REPOS=(
'concourse-mgmt,master',
'ea-uaa-deployment,master',
'extraction-microservice,master',
'identity-microservice,master',
'delivery-ea-tenants-pipelines,master',
'ea-key-generation,master',
'paas-cf-mgmt-aws,main',
'paas-cf-mgmt-aws-nam-mt,main',
'elasticsearch-boshrelease-deployments,master',
'kafka-boshrelease-2.4.x-deployments,master',
'mongodb-boshrelease-3.6.x-deployments,master',
'ea-egw-pipelines,master',
'ea-e2e-smoke,master',
'ea-zookeeper,master',
'dataservices-deployment-bootstrap,master'
)

git --config user.name "CI Bot"
git --config user.email "ci.bot@smarsh.com"

for i in "${REPOS[@]}"
do
  delimiter=","
  declare -a parts=($(echo -e $i | tr "$delimiter" " "))
  repo=${parts[0]}
  branch=${parts[1]}
done

git clone "git@github.com:Smarsh/${repo}.git"
git checkout "${branch}" && git pull origin "${branch}" && git checkout -b pop-release-candidate