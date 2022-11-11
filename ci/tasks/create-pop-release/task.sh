#!/usr/bin/env bash

set -euo pipefail

ls -la delivery-pop-automation
source delivery-pop-automation/.env

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
	$GIT_PRIVATE_KEY
	EOF

	chmod 600 ~/.ssh/id_rsa

	git config --global user.name "Concourse CI Bot"
	git config --global user.email "ci@localhost"
}

setup_git
mkdir build
cd build

function clone_repo(){
	echo -e $GREEN"Cloning Repo ${1}"$WHITE
	git clone git@github.com:Smarsh/${1}.git
}

for repo in "${REPOS[@]}"
do
  clone_repo ${repo}
  cd $repo
  git checkout pop-release-candidate && git pull origin pop-release-candidate && git checkout -b pop-release
  git push --set-upstream origin pop-release -f
  git branch -d pop-release-candidate
  git push origin --delete pop-release-candidate
  cd ..
done

 clone_repo "delivery-ea-versions"
 cd delivery-ea-versions
 if [ `git branch | grep pop-release` ]
 then
    git push origin --delete pop-release
    git checkout aws-us-west-2-poplite-production
    git push origin pop-release
 else
     echo "Branch named pop-release does not exist"
 fi


