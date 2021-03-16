import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
instance_name = sys.argv[3]
command_name = sys.argv[4]

boto_session = get_session(account_number, "TDRJenkinsRunDocumentRole" + stage.capitalize())
client = boto_session.client('ssm', region_name='eu-west-2')

parameter = client.send_command(Targets=[{'Key': 'tag:Name','Values': [instance_name]}], DocumentName=command_name)

print(parameter)
