import sys
from sessions import get_session

# Create IAM client

account_number = sys.argv[1]
stage = sys.argv[2]
function_name = sys.argv[3]

boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client("lambda")

resp = client.invoke(FunctionName=function_name)

print(resp['ResponseMetadata']['RequestId'])