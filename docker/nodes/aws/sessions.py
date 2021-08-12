import boto3
from boto3 import Session

def get_session(account_number, role_name):
    sts_default_provider_chain = boto3.client('sts')

    role_to_assume_arn='arn:aws:iam::' + account_number + ':role/' + role_name

    role_session_name='session'

    response=sts_default_provider_chain.assume_role(
        RoleArn=role_to_assume_arn,
        RoleSessionName=role_session_name
    )

    creds=response['Credentials']

    return Session(
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken'],
    )