import boto3
from boto3 import Session
import sys


# Create IAM client
sts_default_provider_chain = boto3.client('sts')
account_number = sys.argv[1]
stage = sys.argv[2]
service_name = sys.argv[3]

role_to_assume_arn='arn:aws:iam::' + account_number + ':role/TDRJenkinsECSUpdateRole' + stage.capitalize()

role_session_name='session'

response=sts_default_provider_chain.assume_role(
    RoleArn=role_to_assume_arn,
    RoleSessionName=role_session_name
)

creds=response['Credentials']

boto3_session = Session(
    aws_access_key_id=creds['AccessKeyId'],
    aws_secret_access_key=creds['SecretAccessKey'],
    aws_session_token=creds['SessionToken'],
)

client = boto3_session.client('ecs')

resp = client.update_service(cluster=service_name + '_' + stage,service= service_name + '_service_' + stage ,forceNewDeployment=True)

print(resp['service']['serviceArn'])
