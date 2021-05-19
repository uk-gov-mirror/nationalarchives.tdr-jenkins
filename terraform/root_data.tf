data "aws_ssm_parameter" "ami_aws_account" {
  name = "/mgmt/ami_aws_account"
}

data "aws_ssm_parameter" "cost_centre" {
  name = "/mgmt/cost_centre"
}

data "aws_ami" "ecs_ami" {
  # look for the latest public Amazon ECS image from Amazon owned account
  owners      = [data.aws_ssm_parameter.ami_aws_account.value]
  name_regex  = "^amzn2-ami-ecs-hvm-2.0.\\d{8}-x86_64-ebs"
  most_recent = true
}

data "aws_ssm_parameter" "jenkins_backup_healthcheck_url" {
  name = "/mgmt/jenkins/backup/healthcheck/url"
}

data "aws_lambda_function" "notifications_function" {
  function_name = "tdr-notifications-mgmt"
}

data "aws_caller_identity" "current" {}