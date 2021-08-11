import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
function_name = sys.argv[3]
version = sys.argv[4]

function_arn = f'arn:aws:lambda:eu-west-2:{account_number}:function:{function_name}'
boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client("lambda")
event_mappings = client.list_event_source_mappings()['EventSourceMappings']
uuid = list(filter(lambda x: x['FunctionArn'].startswith(function_arn), event_mappings))[0]['UUID']
client.update_event_source_mapping(UUID=uuid, FunctionName=function_arn + ":" + version)