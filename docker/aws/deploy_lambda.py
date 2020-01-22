import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
function_name = sys.argv[3]
file_path = sys.argv[4]

boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client("lambda")

resp = client.update_function_code(FunctionName=function_name, ZipFile=open(file_path, 'rb').read())

print(resp['ResponseMetadata']['RequestId'])
