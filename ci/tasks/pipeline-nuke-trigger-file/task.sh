#!/usr/bin/env bash

set -euo pipefail
: "${REGION:?REGION env var must be provided}"
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${GIT_PRIVATE_KEY:?GIT_PRIVATE_KEY env var must be provided}"
: "${TIER:?TIER env var must be provided}"

source delivery-tenants-api/ci/tasks/pipeline-nuke-trigger-file/trycatch.sh

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"Begin deleting trigger file"${WHITE}
echo -e ${GREEN}"___"${WHITE}

add_config()
{
	mkdir -p ~/.ssh
	cat > ~/.ssh/config <<EOF
		StrictHostKeyChecking no
		LogLevel quiet
EOF
	chmod 0600 ~/.ssh/config
}

eval $(ssh-agent -s)
ssh-add <(echo -e "$GIT_PRIVATE_KEY")
add_config

error_repos=()

try
(
  mkdir tmp
  cd tmp
  git clone "git@github.com:Smarsh/delivery-aws-pipelines.git"
  pushd delivery-aws-pipelines
  git checkout trigger

  git config user.name "Concourse CI Bot"
  git config user.email "ci@localhost"

  triggerfileexists=$(find . -name "trigger-${CLOUD}-${REGION}-${CUSTOMER}-${TIER}")
  if [ "$triggerfileexists" ]
  then
    echo -e ${GREEN}"Deleting trigger file"${WHITE}
    find . -name "trigger-${CLOUD}-${REGION}-${CUSTOMER}-${TIER}" -exec git rm {} \;

    if [ -n "$(git status --porcelain)" ];
    then
      git add .
      git commit -m ":sparkler:	Pipeline - Deleted trigger file"
      git push
    fi
  else
    echo -e ${GREEN}"No trigger file found."${WHITE}
  fi

  popd
  rm -rf tmp
)
catch || {
  echo -e ${RED}"Error with delivery-aws-pipelines"${WHITE}
  error_repos+=("delivery-aws-pipelines")
}

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"End deleting trigger file"${WHITE}
echo -e ${GREEN}"___"${WHITE}

len=${#error_repos[@]}

echo -e ${GREEN}"Len: $len"${WHITE}

if [ $len != 0 ]
then
  for (( i=0; i<$len; i++ ));
  do
    echo -e ${RED}"Error with repo: ${error_repos[$i]}"${WHITE}
  done
  exit 1
else
  echo -e ${GREEN}"No errors."${WHITE}
fi