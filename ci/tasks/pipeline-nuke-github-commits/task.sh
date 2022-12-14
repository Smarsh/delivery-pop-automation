#!/usr/bin/env bash

set -euo pipefail
: "${OKTA_OAUTH2_CLIENT_ID:?OKTA_OAUTH2_CLIENT_ID env var must be provided}"
: "${OKTA_OAUTH2_CLIENT_SECRET:?OKTA_OAUTH2_CLIENT_SECRET env var must be provided}"
: "${GIT_PRIVATE_KEY:?GIT_PRIVATE_KEY env var must be provided}"
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"
: "${REGION:?REGION env var must be provided}"
: "${FLOW_TYPE:?FLOW_TYPE env var must be provided}"
: "${TENANT_NAME:?TENANT_NAME env var must be provided}"


source delivery-tenants-api/ci/tasks/pipeline-nuke-github-commits/trycatch.sh



# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

if [ "$TIER" = "production" ]; then
    export ENVIRONMENT_TYPE='prod'
else
    export ENVIRONMENT_TYPE="${TIER}"
fi

export API_REGION=$(echo "${REGION^^}" | tr '-' '_')



echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"Get auth token"${WHITE}
echo -e ${GREEN}"___"${WHITE}

export OKTA_BASIC_AUTH=$(echo -e -n $OKTA_OAUTH2_CLIENT_ID:$OKTA_OAUTH2_CLIENT_SECRET | base64 -w 0)

export API_URL="https://delivery-tenants-api.apps.us-east-1.aws.smarsh.cloud"

curl -L -s --request POST \
--url https://smarsh.okta.com/oauth2/default/v1/token \
--header 'accept: application/json' \
--header "authorization: Basic $OKTA_BASIC_AUTH" \
--header 'cache-control: no-cache' \
--header 'content-type: application/x-www-form-urlencoded' \
--data 'grant_type=client_credentials&scope=delivery_tenants_api_write' > token.json

AUTH_TOKEN=$(jq -r '.access_token' token.json)

printf "OKTA AUTH_TOKEN: " && printf "${AUTH_TOKEN}" | cut -c2-9

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"Find tenant"${WHITE}
echo -e ${GREEN}"___"${WHITE}

http_code=$(curl -LI --location --request GET "${API_URL}/tenants?page=0&size=1&customer-name=${CUSTOMER}&region=${API_REGION}&environment-type=${ENVIRONMENT_TYPE}&flow-type=${FLOW_TYPE}&tenant-name=${TENANT_NAME}" -o /dev/null --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $AUTH_TOKEN" -w '%{http_code}\n' -s)
if [ ${http_code} -eq 200 ]; then
    TENANT_ID=$(curl --location --request GET "${API_URL}/tenants?page=0&size=1&customer-name=${CUSTOMER}&region=${API_REGION}&environment-type=${ENVIRONMENT_TYPE}&flow-type=${FLOW_TYPE}&tenant-name=${TENANT_NAME}" \
      --header 'Content-Type: application/json' \
      --header 'Accept: application/json' \
      --header "Authorization: Bearer $AUTH_TOKEN" | jq '.[0].id')
else
    echo -e ${GREEN}"Error when calling tenant api"${WHITE}
    exit 1
fi

echo -e ${GREEN}"Tenant id: ${TENANT_ID}"${WHITE}

if [[ "$TENANT_ID" == null ]];
then
  echo -e ${GREEN}"Tenant id is null - exiting"${WHITE}
	exit 0
fi

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"Begin revert GH commits"${WHITE}
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
mkdir tmp && cd tmp
try
(
  echo -e ${GREEN}"Started reverting delivery-ea-versions"${WHITE}
  git clone "git@github.com:Smarsh/delivery-ea-versions.git"
  pushd delivery-ea-versions

  delete=$(git push -d origin "${CLOUD}-${REGION}-${CUSTOMER}-${TIER}" >>/dev/null 2>&1;echo $?)
  delete=$(git branch -d "${CLOUD}-${REGION}-${CUSTOMER}-${TIER}" >>/dev/null 2>&1;echo $?)

  popd
  echo -e ${GREEN}"Finished reverting delivery-ea-versions"${WHITE}
)
catch || {
  echo -e ${RED}"Error with delivery-ea-versions"${WHITE}
  error_repos+=("delivery-ea-versions")
  popd
}

try
(
  echo -e ${GREEN}"Started reverting delivery-aws-pipelines"${WHITE}
  git clone "git@github.com:Smarsh/delivery-aws-pipelines.git"
  pushd delivery-aws-pipelines

  git config user.name "Concourse CI Bot"
  git config user.email "ci@localhost"

  echo -e ${GREEN}"Revert vars files"${WHITE}

  varsexist=$(find . -name "*${CLOUD}-${REGION}-${CUSTOMER}-${TIER}*")
  if [ "$varsexist" ]
  then
    find . -name "*${CLOUD}-${REGION}-${CUSTOMER}-${TIER}*" -exec git rm {} \;

    echo -e ${GREEN}"Revert template file"${WHITE}

    file_exists=$(grep -n "${CUSTOMER}-${TIER}" ci/vars/validate_pr_template.yml >>/dev/null 2>&1;echo $?)
    if [ "$file_exists" -eq 0 ];
    then
      line=$(grep -n "${CUSTOMER}-${TIER}" ci/vars/validate_pr_template.yml | cut -d: -f1)
      echo -e ${GREEN}"Line: $line"${WHITE}
      if [ "$line" ]
      then
        echo -e ${GREEN}"Get next line"${WHITE}
        let nextline=$line+1
        echo -e ${GREEN}"Next line: $nextline"${WHITE}
        sed -i "${line},${nextline}d" ci/vars/validate_pr_template.yml
        echo -e ${GREEN}"Lines removed"${WHITE}
      fi
    fi

    if [ -n "$(git status --porcelain)" ];
    then
      git add .
      git commit -m ":sparkler:	${CUSTOMER}-${TIER} - Reverted vars files"
      git push
    fi
  fi

  popd
  echo -e ${GREEN}"Finished reverting delivery-aws-pipelines"${WHITE}
)
catch || {
  echo -e ${RED}"Error with delivery-aws-pipelines"${WHITE}
  error_repos+=("delivery-aws-pipelines")
  popd
}

try
(
  echo -e ${GREEN}"Started reverting paas-cf-mgmt-aws-non-prod"${WHITE}
  git clone "git@github.com:Smarsh/paas-cf-mgmt-aws-non-prod.git"
  pushd paas-cf-mgmt-aws-non-prod

  git config user.name "Concourse CI Bot"
  git config user.email "ci@localhost"

  echo -e ${GREEN}"Revert enterprise archive and email gateway files for ${CUSTOMER}-${TIER}"${WHITE}

  customer_exists=$(cat config/enterprise-archive/spaces.yml | grep "${CUSTOMER}-${TIER}" >>/dev/null 2>&1;echo $?)
  echo -e ${GREEN}"Customer exists? ${customer_exists}"${WHITE}

  if [ "customer_exists" -eq 0 ];
  then
    line=$(grep -n "${CUSTOMER}-${TIER}" config/enterprise-archive/spaces.yml | cut -d: -f1)
    echo -e ${GREEN}"Revert spaces file"${WHITE}
    sed -i "${line},${line}d" config/enterprise-archive/spaces.yml

    git add .
    git commit -m ":sparkler:	${CUSTOMER}-${TIER} - Reverted all PCF Spaces"
    git push
  fi

#     if [ -d "config/email-gateway/poplite-production" ]
#     then
#       echo -e ${GREEN}"Revert email gateway files"${WHITE}
#       git rm config/email-gateway/poplite-production -r
#       git add .
#       git commit -m "Reverted email gateway files"
#       git push
#     fi

  if [ -d "config/enterprise-archive/${CUSTOMER}-${TIER}" ]
  then
    echo -e ${GREEN}"Revert enterprise archive files"${WHITE}
    git rm config/enterprise-archive/${CUSTOMER}-${TIER} -r
    git add .
    git commit -m ":sparkler:	${CUSTOMER}-${TIER} - Reverted enterprise archive files"
    git push
  fi

  popd
  echo -e ${GREEN}"Finished reverting paas-cf-mgmt-aws-non-prod"${WHITE}
)
catch || {
  echo -e ${RED}"Error with paas-cf-mgmt-aws-non-prod"${WHITE}
  error_repos+=("paas-cf-mgmt-aws-non-prod")
  popd
}

try
(
  echo -e ${GREEN}"Started reverting ea-platform-sre-team"${WHITE}
  git clone "git@github.com:Smarsh/ea-platform-sre-team.git"
  pushd ea-platform-sre-team

  git config user.name "Concourse CI Bot"
  git config user.email "ci@localhost"

  echo -e ${GREEN}"Remove ${CUSTOMER}-${TIER} files"${WHITE}
  find . -name '*${CUSTOMER}-${TIER}*' -exec git rm {} \;

  echo -e ${GREEN}"Find ${CUSTOMER}-${TIER} line"${WHITE}
  line_exists=$(grep -n "${CUSTOMER}-${TIER}" datadog/terraform-code/lag_drain_rate_dashboard_variable.tf >>/dev/null 2>&1;echo $?)
  echo -e ${GREEN}"Line exists: $line_exists"${WHITE}
  if [ "$line_exists" -eq 0 ];
  then
    echo -e ${GREEN}"Getting line"${WHITE}
    line=$(grep -n "${CUSTOMER}-${TIER}" datadog/terraform-code/lag_drain_rate_dashboard_variable.tf | cut -d: -f1 >>/dev/null 2>&1;echo $?)
    echo -e ${GREEN}"Delete ${CUSTOMER}-${TIER} line"${WHITE}
    sed -i "${line},${line}d" datadog/terraform-code/lag_drain_rate_dashboard_variable.tf
  fi

  echo -e ${GREEN}"Seeing if anything has changed"${WHITE}
  if [ -n "$(git status --porcelain)" ];
  then
    echo -e ${GREEN}"Commit to GitHub"${WHITE}
    git add .
    git commit -m ":sparkler:	${CUSTOMER}-${TIER} - Revert deployment files"
    git push
  else
    echo -e ${GREEN}"Nothing to commit"${WHITE}
  fi

  popd
  echo -e ${GREEN}"Finished reverting ea-platform-sre-team"${WHITE}
)
catch || {
  echo -e ${RED}"Error with ea-platform-sre-team"${WHITE}
  error_repos+=("ea-platform-sre-team")
  popd
}

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
'ea-zookeeper,master'
)

for i in "${REPOS[@]}"
do
  delimiter=","
  declare -a parts=($(echo -e $i | tr "$delimiter" " "))
  repo=${parts[0]}
  branch=${parts[1]}

  echo -e ${GREEN}"Started reverting ${repo}"${WHITE}

  git clone "git@github.com:Smarsh/${repo}.git"
  pushd $repo

  git config user.name "Concourse CI Bot"
  git config user.email "ci@localhost"

  git checkout "${branch}"
  git pull

  temp=$(git log --grep="^:robot: POP Automation -> deploymentId:{{$TENANT_ID}}" --format=format:%H)
  reverted=$(git log --grep="^Revert \":robot: POP Automation -> deploymentId:{{$TENANT_ID}}\"" --format=format:%H)
  delimiter="\n"
  declare -a revertedshas=($(echo -e "$reverted" | tr "$delimiter" " "))
  if ((${#revertedshas[@]}));
  then
    echo -e ${YELLOW}"This commit has already been reverted"${WHITE}
  else
    declare -a shas=($(echo -e "$temp" | tr "$delimiter" " "))

    for i in "${shas[@]}"
    do
      st="$(git revert --no-edit "$i" >>/dev/null 2>&1;echo $?)"
      if [ "$st" -eq 1 ]; then
        echo -e "${RED}Error reverting repo ${repo} SHA ${i}"${WHITE}
        error_repos+=($repo)
      elif [ "$st" -eq 0 ]; then
        st="$(git push >>/dev/null 2>&1;echo $?)"
        if [ "$st" -eq 1 ]; then
          echo -e "${RED}Error pushing to repo ${repo}"${WHITE}
          error_repos+=($repo)
        fi
      fi
    done
  fi

  popd

  echo -e ${GREEN}"Finished reverting ${repo}"${WHITE}

done

echo -e ${GREEN}"___"${WHITE}
echo -e ${GREEN}"End revert GH commits"${WHITE}
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

for i in "${REPOS[@]}"
do
  delimiter=","
  declare -a parts=($(echo -e $i | tr "$delimiter" " "))
  repo=${parts[0]}
  branch=${parts[1]}

  cd ${repo}
  git checkout "${branch}"

  DIRS=( $(find . -type d -name "*${CUSTOMER}-${TIER}*" ) )
  FILES=( $(find . -type f -name "*${CUSTOMER}-${TIER}*" ) )

for i in "${DIRS[@]}"
do
  if [ -d "${i}" ]
  then
    echo "This is a directory: ${i}..."
    rm -r "$i"
  else
    echo "This is not a directory: ${i}..."
  fi
done

for i in "${FILES[@]}"
do
  if [ -f "${i}" ]
  then
    echo "This is a file: ${i}"
    rm "$i"
  else
    echo "This file does not exist: ${i}..."
  fi
done
done