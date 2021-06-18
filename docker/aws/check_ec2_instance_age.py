import sys
from sessions import get_session
from datetime import datetime

account_number = sys.argv[1]
stage = sys.argv[2]
instance_name = sys.argv[3]
age = sys.argv[4]

boto_session = get_session(account_number, "TDRJenkinsDescribeEC2Role" + stage.capitalize())

client = boto_session.client("ec2")

resp = client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [instance_name]}])
d = datetime.fromisoformat("2021-06-08T15:42:22+00:00")
reservations = resp["Reservations"]
if len(reservations) > 0:
    instances = reservations[0]["Instances"][0]
    launch_time = reservations[0]["Instances"][0]["LaunchTime"]
    now = datetime.now(launch_time.tzinfo)
    print((now - launch_time).days > int(age))
else:
    print("False")
