#!/usr/bin/env bash

set -euo pipefail
: "${CUSTOMER:?CUSTOMER env var must be provided}"
: "${TIER:?TIER env var must be provided}"

# Set colours
GREEN="\e[32m"
RED="\e[41m\e[37m\e[1m"
YELLOW="\e[33m"
WHITE="\e[0m"

mkdir terraform_workspace

##UAA Deletion
cd delivery-pop-automation
KEY_PATH=`aws s3 ls s3://smarsh-terraform-state-management-${REGION_BUCKET_SUFFIX} --recursive --no-paginate | grep -w ${CUSTOMER} | grep ${TIER} | grep uaa | cut -d " " -f 9`
envsubst < vars/main_template.json > temp.tf && mv temp.tf terraform_workspace/main.tf
cd ../

cd terraform_workspace
terraform init -reconfigure
aws rds modify-db-instance --db-instance-identifier eadb-uaa-postgres-${CUSTOMER}-${TIER} --region ${CLOUD_REGION} --no-deletion-protection --apply-immediately > output.txt
terraform plan -destroy
# terraform apply -destroy -auto-approve
cd ../

##TPS Deletion
cd delivery-pop-automation
KEY_PATH=`aws s3 ls s3://smarsh-terraform-state-management-${REGION_BUCKET_SUFFIX} --recursive --no-paginate | grep -w ${CUSTOMER} | grep ${TIER} | grep tps | cut -d " " -f 9`
envsubst < vars/main_template.json > temp.tf && mv temp.tf terraform_workspace/main.tf
cd ../

cd terraform_workspace
terraform init -reconfigure
aws rds modify-db-instance --db-instance-identifier eadb-egw-tps-postgres-tpspostgres-${CUSTOMER}-${TIER} --region ${CLOUD_REGION} --no-deletion-protection --apply-immediately > output.txt
terraform plan -destroy
# terraform apply -destroy -auto-approve
cd ../

