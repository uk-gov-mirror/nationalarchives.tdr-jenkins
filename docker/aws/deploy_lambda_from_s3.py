import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
function_name = sys.argv[3]
s3_bucket = sys.argv[4]
s3_key = sys.argv[5]

boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client("lambda")

client.update_function_code(FunctionName=function_name, S3Bucket=s3_bucket, S3Key=s3_key)
response = client.publish_version(FunctionName=function_name)
function_arn = 'arn:aws:lambda:eu-west-2:' + account_number + ':function:' + function_name
event_mappings = client.list_event_source_mappings()['EventSourceMappings']
version = response["Version"]
uuid = list(filter(lambda x: x['FunctionArn'].startswith(function_arn), event_mappings))[0]['UUID']
client.update_event_source_mapping(UUID=uuid, FunctionName=function_arn + ":" + version)
print("v" + version)
