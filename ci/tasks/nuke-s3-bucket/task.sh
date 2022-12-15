#!/bin/bash
S3_BUCKET="$object_prefix$Tenant_Name"
aws configure set aws_access_key_id "$aws_access_key_id"
aws configure set aws_secret_access_key "$aws_secret_access_key"
aws configure set region "$region"

#check bucket exist
# if [ $(aws s3 ls "s3://$S3_BUCKET" | grep 'NoSuchBucket' &> /dev/null) == 0 ] 
# then
#     echo "$S3_BUCKET doesn\'t exist please check again"
#     exit
# else
#     echo "$S3_BUCKET exist, deletion in progress"
# fi

#delete bucket
echo "$S3_BUCKET"
aws s3 rm s3://$S3_BUCKET --recursive