#!/usr/bin/env bash

set -euo pipefail

REPOS=(
'concourse-mgmt,pop-release-candidate',
'ea-uaa-deployment,pop-release-candidate',
'extraction-microservice,pop-release-candidate',
'identity-microservice,pop-release-candidate',
'delivery-ea-tenants-pipelines,pop-release-candidate',
'ea-key-generation,pop-release-candidate',
'paas-cf-mgmt-aws,pop-release-candidate',
'paas-cf-mgmt-aws-nam-mt,pop-release-candidate',
'elasticsearch-boshrelease-deployments,pop-release-candidate',
'kafka-boshrelease-2.4.x-deployments,pop-release-candidate',
'mongodb-boshrelease-3.6.x-deployments,pop-release-candidate',
'ea-egw-pipelines,pop-release-candidate',
'ea-e2e-smoke,pop-release-candidate',
'ea-zookeeper,pop-release-candidate',
'dataservices-deployment-bootstrap,pop-release-candidate'
)

for i in "${REPOS[@]}"
do
  delimiter=","
  declare -a parts=($(echo -e $i | tr "$delimiter" " "))
  repo=${parts[0]}
  branch=${parts[1]}
  if [repo !== delivery-ea-versions-api] ; then
    git checkout "${branch}" && git push "${branch}" -f
  else
    #There is an exception for the ea-versions repo where the force push will be aws-us-west-2-poplite-production-> pop-stable
  fi
done





#Inject a new step CREATE_POP_RELEASE programmatically that runs only for poplite
#Priority 800 - should run after RUN_E2E_SANITY_PIPELINE
#The pop entrypoint for this step should do a force push on all the repos pop-release-candidate → pop-stable
#There is an exception for the ea-versions repo where the force push will be aws-us-west-2-poplite-production-> pop-stable