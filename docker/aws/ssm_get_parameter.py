import sys
from sessions import get_session

# This script will retrieve the SSM param and prints the value
# Too ensure the value does not appear in the console run the script with set+x command this will hide the output on the console:
# sh """
#   set +x
#   [command that uses script]
# """

account_number = sys.argv[1]
stage = sys.argv[2]
param_name = sys.argv[3]

boto_session = get_session(account_number, "TDRJenkinsReadParamsRole" + stage.capitalize())
client = boto_session.client('ssm', region_name='eu-west-2')

parameter = client.get_parameters(Names=[param_name], WithDecryption=True)

print(parameter['Parameters'][0]['Value'])
