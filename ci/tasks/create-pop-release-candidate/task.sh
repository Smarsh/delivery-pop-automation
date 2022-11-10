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

for i in "${REPOS[@]}"
do
  delimiter=","
  declare -a parts=($(echo -e $i | tr "$delimiter" " "))
  repo=${parts[0]}
  branch=${parts[1]}
  clone_repo(${repo})
  cd $repo
  git checkout "${branch}" && git pull origin "${branch}" && git checkout -b pop-release-candidate
  git push --set-upstream origin "${branch}" -f
  cd ..
done


