import sys
from sessions import get_session

account_number = sys.argv[1]
stage = sys.argv[2]
service_to_deploy = sys.argv[3]

boto_session = get_session(account_number, "TDRJenkinsDeployServiceUnavailableRole" + stage.capitalize())

client = boto_session.client("elbv2")

alb_name = f"tdr-frontend-{stage}"

load_balancers = client.describe_load_balancers()["LoadBalancers"]
frontend_load_balancer_arn = [lb for lb in load_balancers if lb["LoadBalancerName"] == alb_name][0]["LoadBalancerArn"]
listeners = client.describe_listeners(LoadBalancerArn=frontend_load_balancer_arn)["Listeners"]
frontend_https_listener_arn = [li for li in listeners if alb_name in li["ListenerArn"]][0]["ListenerArn"]

if service_to_deploy == "ServiceUnavailable":
    target_group_prefix = "tdr-su-"
else:
    target_group_prefix = "tdr-frontend-"

target_groups = client.describe_target_groups()["TargetGroups"]
target_group = [tg for tg in target_groups if tg["TargetGroupName"].startswith(target_group_prefix)][0]

default_action = {
    "Type": "forward",
    "TargetGroupArn": target_group["TargetGroupArn"]
}
response = client.modify_listener(
    ListenerArn=frontend_https_listener_arn,
    Port=443,
    Protocol="HTTPS",
    DefaultActions=[default_action]
)

