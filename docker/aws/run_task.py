import boto3
import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
cluster = sys.argv[3]
task = sys.argv[4]

boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client('ecs')
ec2_client = boto_session.client("ec2")

security_groups = [x['GroupId'] for x in list(filter(lambda x: x['GroupName'] == "tdr-outbound-only", ec2_client.describe_security_groups()['SecurityGroups']))]
subnets = [x['SubnetId'] for x in ec2_client.describe_subnets(Filters=[
    {
        'Name': 'tag:Name',
        'Values': [
            'tdr-private-subnet-0-' + stage,
            'tdr-private-subnet-1-' + stage,
            ]
    },
])['Subnets']]

response = client.run_task(
    cluster=cluster,
    taskDefinition=task,
    launchType="FARGATE",
    platformVersion="1.4.0",
    networkConfiguration = {
        'awsvpcConfiguration': {
            'subnets' : subnets,
            'securityGroups': security_groups
        }
    }
)
