import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
function_name = sys.argv[3]

boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client("lambda")

args = '{"stage": "%s"}' % stage

payload = bytearray()
payload.extend(args.encode())

resp = client.invoke(FunctionName=function_name, Payload=payload)

print(resp['ResponseMetadata']['RequestId'])
