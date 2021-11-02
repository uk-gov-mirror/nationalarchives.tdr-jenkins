import sys
from sessions import get_session
import boto3

account_number = sys.argv[1]
stage = sys.argv[2]
function_name = sys.argv[3]
s3_bucket = sys.argv[4]
s3_key = sys.argv[5]


def publish_lambda_version():
  publish_response = client.publish_version(FunctionName=function_name)
  print(publish_response["Version"])


if stage == "mgmt":
  client = boto3.client("lambda")
else:
  boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())
  client = boto_session.client("lambda")

function_updated_waiter = client.get_waiter('function_updated')

update_response = client.update_function_code(FunctionName=function_name, S3Bucket=s3_bucket, S3Key=s3_key)

function_updated_waiter.wait(
  FunctionName=function_name
)

publish_lambda_version()
