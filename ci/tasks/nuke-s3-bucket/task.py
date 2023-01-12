import os
import yaml
import time
import boto3
from botocore.exceptions import ClientError

client=boto3.client("s3",region_name=os.getenv('region'),aws_access_key_id=os.getenv('aws_access_key_id'), aws_secret_access_key=os.getenv('aws_secret_access_key'))
s3 = boto3.resource(service_name='s3',  region_name=os.getenv('region'),aws_access_key_id=os.getenv('aws_access_key_id'), aws_secret_access_key=os.getenv('aws_secret_access_key'))
print("conntect to s3")

env_space_name=os.getenv('env_space_name')
object_store_prefix=os.getenv('object_store_prefix')

# Getting all tenants from env_space_name_tenant_provisioning.yml
def get_tenant_list(filename):   
    tenants = []
    os.chdir(r"delivery-aws-pipelines/ci/vars")
    with open(filename, "r") as f:
        yamldoc = yaml.safe_load(f)
        for tenant in yamldoc["customer_tenants"]:
            tenants.append(tenant["name"])
    return tenants

# Generating Bucket name by adding object_store_prefix + tenant_name
def get_buckets_to_delete(tenants):
        buckets_to_delete=[]
        for tenant in tenants:
                # Tenant Bucket
                buckets_to_delete.append(object_store_prefix+tenant)
                # eventlog Bucket
                buckets_to_delete.append("eventlog-"+tenant+"-"+env_space_name)
        return buckets_to_delete

## This is for test and first time only
# Printing buckets name and waiting for 30 minutes before deleting
tenants_list = get_tenant_list(env_space_name + "_tenant_provisioning.yml")
buckets_to_delete = get_buckets_to_delete(tenants_list)
for bucket_name in buckets_to_delete:
        print(bucket_name)
time.sleep(60*30)


# deleting buckets
for bucket_name in buckets_to_delete:
        # try:
        #         bucket_versioning = s3.BucketVersioning(bucket_name).status
        #         print(bucket_versioning)
        # except ClientError as e:
        #         if e.response['Error']['Code'] == 'NoSuchBucket':
        #                 print("Bucket did not exists")
        #         else:
        #                 print("Unexpected error: %s" % e)
        try:
                s3.Bucket(bucket_name).object_versions.delete()
                client.delete_bucket(Bucket=bucket_name)
                print("")
        except ClientError as e:
                if e.response['Error']['Code'] == 'NoSuchBucket':
                        print("Bucket did not exists")
                else:
                        print("Unexpected error: %s" % e)
