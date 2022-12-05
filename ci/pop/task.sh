#!/usr/bin/env bash

set -euo pipefail

source pop-input/.env

: "${CLOUD:?CLOUD env var must be provided}"
: "${REGION:?REGION env var must be provided}"
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${GITHUB_PRIVATE_KEY:?GITHUB_PRIVATE_KEY env var must be provided}"
: "${TENANT_ID:?TENANT_ID env var must be provided}"

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

GH_REPO='delivery-pop-automation'

export ENVIRONMENT_NAME="platform-delivery-${TIER}-${CLOUD}-${REGION}"

function update_repo(){
  if [ -n "$(git status --porcelain)" ]; then
    git add --all
    git commit -m ":robot: POP Automation -> deploymentId:{{${TENANT_ID}}}"
    git push
  else
    echo -e $YELLOW"No changes"$WHITE
  fi
}

echo -e $GREEN"Setup GH SSH Client"$WHITE
mkdir ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null;

cat <<EOF > ~/.ssh/id_rsa
$GITHUB_PRIVATE_KEY
EOF

chmod 600 ~/.ssh/id_rsa

git config --global user.name "Concourse CI Bot"
git config --global user.email "ci@localhost"

echo -e $GREEN"Cloning Repo $GH_REPO"$WHITE
mkdir build && cd build
git clone git@github.com:Smarsh/${GH_REPO}.git

cd ${GH_REPO}

if [[ -f "ci/vars/${ENVIRONMENT_NAME}.yml" ]]; then
  echo -e $YELLOW"Vars file ${ENVIRONMENT_NAME} already exists - skipping"$WHITE
else
  echo -e $GREEN"Creating vars file for ${ENVIRONMENT_NAME}"$WHITE
  cp ci/vars/template.yml ci/vars/${ENVIRONMENT_NAME}.yml

  echo -e $GREEN"environment variables substitution for ${ENVIRONMENT_NAME}"$WHITE
  envsubst < ci/vars/${ENVIRONMENT_NAME}.yml > temp.yml && mv temp.yml ci/vars/${ENVIRONMENT_NAME}.yml
fi

update_repo
echo -e $GREEN"Done"$WHITE