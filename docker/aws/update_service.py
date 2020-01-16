import sys
from sessions import get_session

# Create IAM client

account_number = sys.argv[1]
stage = sys.argv[2]
service_name = sys.argv[3]

boto3_session = get_session(account_number, 'TDRJenkinsECSUpdateRole' + stage.capitalize())

client = boto3_session.client('ecs')

resp = client.update_service(cluster=service_name + '_' + stage,service= service_name + '_service_' + stage ,forceNewDeployment=True)

print(resp['service']['serviceArn'])
