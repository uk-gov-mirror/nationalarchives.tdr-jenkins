import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
s3_bucket = sys.argv[3]
s3_key = sys.argv[4]
filename = sys.argv[5]

boto_session = get_session(account_number, "TDRJenkinsLambdaRole" + stage.capitalize())

client = boto_session.client("s3")

response = client.upload_file(filename, s3_bucket, s3_key)

print(response)
