module "jenkins_integration_ecs" {
  source               = "./tdr-terraform-modules/ecs"
  common_tags          = local.common_tags
  project              = "tdr"
  vpc_id               = module.jenkins_vpc.vpc_id
  name                 = "jenkins"
  jenkins              = true
  task_role_arn        = module.jenkins_integration_ecs_task_role.role.arn
  execution_role_arn   = module.jenkins_integration_execution_role.role.arn
  alb_target_group_arn = module.jenkins_integration_alb.alb_target_group_arn
}

module "ecr_jenkins_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_integration_execution_role.role.arn }
}

module "jenkins_integration_dns" {
  source                = "./tdr-terraform-modules/route53"
  common_tags           = local.common_tags
  environment_full_name = "management"
  project               = "tdr"
  alb_dns_name          = module.jenkins_integration_alb.alb_dns_name
  alb_zone_id           = module.jenkins_integration_alb.alb_zone_id
  a_record_name         = "jenkins"
}

module "jenkins_integration_ec2" {
  source              = "./tdr-terraform-modules/ec2"
  ami_id              = module.jenkins_ami.encrypted_ami_id
  common_tags         = local.common_tags
  environment         = local.environment
  name                = local.ec2_instance_name
  subnet_id           = module.jenkins_vpc.private_subnets[1]
  security_group_id   = module.jenkins_ec2_security_group.security_group_id
  attach_policies     = { ec2_policy = module.jenkins_ec2_policy.policy_arn, cloudwatch_agent_policy = module.jenkins_cloudwatch_agent_policy.policy_arn, publish_policy = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/TDRJenkinsPublishPolicy" }
  private_ip          = "10.0.1.221"
  user_data           = "user_data_jenkins_docker"
  user_data_variables = { jenkins_cluster_name = "jenkins-${local.environment}", agent_policy_parameter_name = "/${local.environment}/cloudwatch/agent/integration/policy" }
  instance_type       = "t2.medium"
  volume_size         = 120
}

# Configure Jenkins backup using Systems Manager Maintenance Windows
module "jenkins_integration_backup_maintenance_window" {
  source          = "./tdr-terraform-modules/ssm_maintenance_window"
  command         = "docker exec $(docker ps -aq -f ancestor=${module.jenkins_ecr_repository.repository.repository_url} -f status=running) /opt/backup.sh ${data.aws_ssm_parameter.jenkins_backup_healthcheck_url.value}"
  ec2_instance_id = module.jenkins_integration_ec2.instance_id
  name            = "tdr-jenkins-backup-window"
  schedule        = "cron(0 0 18 ? * MON-FRI *)"
  common_tags     = local.common_tags
}

module "jenkins_integration_maintenance_window_event" {
  source                  = "./tdr-terraform-modules/cloudwatch_events"
  event_pattern           = "jenkins_maintenance_event_window"
  lambda_event_target_arn = list(data.aws_lambda_function.notifications_function.arn)
  rule_name               = "jenkins-backup-maintenance-window"
  rule_description        = "Capture failed runs of the jenkins backup"
  event_variables         = { window_id = module.jenkins_integration_backup_maintenance_window.window_id }
}

module "jenkins_integration_fargate_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsFargatePolicy${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_fargate_integration.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_integration_fargate_role" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  assume_role_policy = templatefile("./tdr-terraform-modules/iam_policy/templates/assume_role_policy.json.tpl", { role_arn = module.jenkins_integration_ecs_task_role.role.arn })
  name               = "TDRJenkinsFargateRole${title(local.environment)}"
  policy_attachments = { fargate_policy = module.jenkins_integration_fargate_policy.policy_arn, ssm_core = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
}

module "jenkins_backup_s3" {
  source      = "./tdr-terraform-modules/s3"
  project     = "tdr"
  function    = "jenkins-backup"
  common_tags = local.common_tags
}

module "jenkins_s3_backup_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsS3BackupPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_backup_s3_policy.json.tpl", {})
}

module "jenkins_integration_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "jenkins"
  dns_zone    = var.dns_zone
  domain_name = var.domain_name
  common_tags = local.common_tags
}

module "jenkins_integration_alb" {
  source                           = "./tdr-terraform-modules/alb"
  project                          = var.project
  function                         = var.function
  environment                      = local.environment
  alb_log_bucket                   = module.jenkins_logs_s3.s3_bucket_id
  alb_security_group_id            = module.jenkins_alb_security_group.security_group_id
  certificate_arn                  = module.jenkins_integration_certificate.certificate_arn
  health_check_unhealthy_threshold = 5
  public_subnets                   = module.jenkins_vpc.public_subnets
  target_id                        = module.jenkins_integration_ec2.instance_id
  vpc_id                           = module.jenkins_vpc.vpc_id
  common_tags                      = local.common_tags
}

module "jenkins_integration_ecs_task_role" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  name               = "TDRJenkinsAppTaskRole${title(local.environment)}"
  policy_attachments = {
    task_policy       = module.jenkins_integration_task_policy.policy_arn,
    cloudwatch_policy = module.jenkins_integration_task_cloudwatch_policy.policy_arn,
    s3_policy         = module.jenkins_s3_backup_policy.policy_arn
  }
}

module "jenkins_integration_task_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsTaskPolicy${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_task.json.tpl", { account_id = data.aws_caller_identity.current.account_id, sandbox_account_id = data.aws_ssm_parameter.sandbox_account.value })
}

module "jenkins_integration_task_cloudwatch_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsCloudwatchPolicyMgmt"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_task_integration_cloudwatch.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_integration_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  name               = "TDRJenkinsAppExecutionRole${title(local.environment)}"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  policy_attachments = { execution_policy = module.jenkins_integration_execution_policy.policy_arn, cloudwatch_policy = module.jenkins_integration_task_cloudwatch_policy.policy_arn }
}

module "jenkins_integration_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsExecutionPolicyMgmt"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_execution_integration.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_integration_cloudwatch_ssm_parameter" {
  source      = "./tdr-terraform-modules/ssm_parameter"
  common_tags = local.common_tags
  parameters = [
    { name = "/${local.environment}/cloudwatch/agent/integration/policy", description = "The configuration for Jenkins Cloudwatch Agent", type = "String", value = templatefile("./tdr-terraform-modules/ssm_parameter/templates/jenkins_cloudwatch_agent.json.tpl", { server_name = "Jenkins" }) }
  ]
}

module "jenkins_integration_disk_space_alarm" {
  source             = "./tdr-terraform-modules/cloudwatch_alarms"
  environment        = local.environment
  function           = "jenkins-disk-space-alarm"
  metric_name        = "disk_used_percent"
  project            = var.project
  threshold          = 70
  notification_topic = module.notifications_topic.sns_arn
  dimensions = {
    server_name = "Jenkins"
    host        = module.jenkins_integration_ec2.private_dns
    device      = "xvda1"
    fstype      = "ext4"
    path        = "/"
  }
}
