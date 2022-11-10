#!/usr/bin/env bash

set -euo pipefail

REPOS=(
'concourse-mgmt',
'ea-uaa-deployment',
'extraction-microservice',
'identity-microservice',
'delivery-ea-tenants-pipelines',
'ea-key-generation',
'paas-cf-mgmt-aws',
'paas-cf-mgmt-aws-nam-mt',
'elasticsearch-boshrelease-deployments',
'kafka-boshrelease-2.4.x-deployments',
'mongodb-boshrelease-3.6.x-deployments',
'ea-egw-pipelines',
'ea-e2e-smoke',
'ea-zookeeper',
'dataservices-deployment-bootstrap'
)

source .env

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

function setup_git(){
	echo -e $GREEN"Setup GH SSH Client"$WHITE
	mkdir ~/.ssh
	ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null;

	cat <<-EOF > ~/.ssh/id_rsa
	$GIT_PRIVATE_KEY_RSA_BASE64
	EOF

	chmod 600 ~/.ssh/id_rsa

	git config --global user.name "Concourse CI Bot"
	git config --global user.email "ci@localhost"
}

function clone_repo(repo){
	echo -e $GREEN"Cloning Repo $repo"$WHITE
	git clone git@github.com:Smarsh/${repo}.git
}

setup_git
mkdir build
cd build

for repo in "${REPOS[@]}"
do
  clone_repo(${repo})
  cd $repo
  git checkout pop-release-candidate && git pull origin pop-release-candidate && git checkout -b pop-stable
  git push --set-upstream origin pop-stable -f
  git branch -d pop-release-candidate
  git push origin --delete pop-release-candidate
  cd ..
done


