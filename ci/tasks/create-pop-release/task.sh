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

git --config user.name "CI Bot"
git --config user.email "ci.bot@smarsh.com"

for i in "${REPOS[@]}"
do
  delimiter=","
  declare -a parts=($(echo -e $i | tr "$delimiter" " "))
  repo=${parts[0]}
  branch=${parts[1]}
  if [repo !== delivery-ea-versions-api] ; then
    git checkout "${branch}" && git push --set-upstream origin "${branch}" -f
  else
    #There is an exception for the ea-versions repo where the force push will be aws-us-west-2-poplite-production-> pop-stable
  fi
  git push origin --delete "${branch}"
done

