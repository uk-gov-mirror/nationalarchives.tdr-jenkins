import sys
from docker.aws.sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
param_name = sys.argv[3]

boto_session = get_session(account_number, "TDRJenkinsReadParamsRole" + stage.capitalize())
client = boto_session.client('ssm', region_name='eu-west-2')

parameter = client.get_parameters(Names=[param_name], WithDecryption=True)

print(parameter['Parameters'][0]['Value'])
