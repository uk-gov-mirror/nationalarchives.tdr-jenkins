module "jenkins_ecr_repository_prod" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-prod"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/Dockerfile-prod"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_ecs_execution_role_prod.role.arn }
}

module "jenkins_ecs_prod" {
  source               = "./tdr-terraform-modules/ecs"
  common_tags          = local.common_tags
  project              = "tdr"
  vpc_id               = module.jenkins_vpc.vpc_id
  name                 = "jenkins-prod"
  jenkins              = true
  task_role_arn        = module.jenkins_ecs_task_role_prod.role.arn
  execution_role_arn   = module.jenkins_ecs_execution_role_prod.role.arn
  alb_target_group_arn = module.jenkins_alb_prod.alb_target_group_arn
}

module "jenkins_dns_prod" {
  source                = "./tdr-terraform-modules/route53"
  common_tags           = local.common_tags
  environment_full_name = "management"
  project               = "tdr"
  alb_dns_name          = module.jenkins_alb_prod.alb_dns_name
  alb_zone_id           = module.jenkins_alb_prod.alb_zone_id
  a_record_name         = "jenkins-prod"
}

module "jenkins_ec2_prod" {
  source              = "./tdr-terraform-modules/ec2"
  ami_id              = module.jenkins_ami.encrypted_ami_id
  common_tags         = local.common_tags
  environment         = local.environment
  name                = "JenkinsProduction"
  subnet_id           = module.jenkins_vpc.private_subnets[1]
  security_group_id   = module.jenkins_ec2_security_group.security_group_id
  attach_policies     = { ec2_policy = module.jenkins_ec2_policy.policy_arn }
  private_ip          = "10.0.1.222"
  user_data           = "user_data_jenkins_docker"
  user_data_variables = { jenkins_cluster_name = "jenkins-prod-${local.environment}" }
  instance_type       = "t2.medium"
  volume_size         = 60
}

# Configure Jenkins backup using Systems Manager Maintenance Windows
module "jenkins_backup_maintenance_window_prod" {
  source          = "./tdr-terraform-modules/ssm_maintenance_window"
  command         = "docker exec $(docker ps -aq -f ancestor=${module.jenkins_ecr_repository_prod.repository.repository_url} -f status=running) /opt/backup.sh ${data.aws_ssm_parameter.jenkins_backup_prod_healthcheck_url.value}"
  ec2_instance_id = module.jenkins_ec2_prod.instance_id
  name            = "tdr-jenkins-backup-prod-window"
  schedule        = "cron(0 0 18 ? * MON-FRI *)"
  common_tags     = local.common_tags
}

module "jenkins_maintenance_window_event_prod" {
  source                  = "./tdr-terraform-modules/cloudwatch_events"
  event_pattern           = "jenkins_maintenance_event_window"
  lambda_event_target_arn = list(data.aws_lambda_function.notifications_function.arn)
  rule_name               = "jenkins-backup-maintenance-window-prod"
  rule_description        = "Capture failed runs of the jenkins backup"
  event_variables         = { window_id = module.jenkins_backup_maintenance_window_prod.window_id }
}

module "jenkins_fargate_policy_prod" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsFargateProdPolicy${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_fargate_prod.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_fargate_role_prod" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  assume_role_policy = templatefile("./tdr-terraform-modules/iam_policy/templates/assume_role_policy.json.tpl", { role_arn = module.jenkins_ecs_task_role_prod.role.arn })
  name               = "TDRJenkinsFargateRoleProd${title(local.environment)}"
  policy_attachments = { fargate_policy = module.jenkins_fargate_policy_prod.policy_arn, ssm_core = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
}

module "jenkins_certificate_prod" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "jenkins-prod"
  dns_zone    = var.dns_zone
  domain_name = "jenkins-prod.tdr-management.nationalarchives.gov.uk"
  common_tags = local.common_tags
}

module "jenkins_alb_prod" {
  source                           = "./tdr-terraform-modules/alb"
  project                          = var.project
  function                         = "jenkins-prod"
  environment                      = local.environment
  alb_log_bucket                   = module.jenkins_logs_s3.s3_bucket_id
  alb_security_group_id            = module.jenkins_alb_security_group.security_group_id
  certificate_arn                  = module.jenkins_certificate_prod.certificate_arn
  health_check_unhealthy_threshold = 5
  public_subnets                   = module.jenkins_vpc.public_subnets
  target_id                        = module.jenkins_ec2_prod.instance_id
  vpc_id                           = module.jenkins_vpc.vpc_id
  common_tags                      = local.common_tags
}

module "jenkins_s3_backup_policy_prod" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsS3BackupPolicyProd"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_backup_prod_s3_policy.json.tpl", {})
}

module "jenkins_ecs_task_role_prod" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  name               = "TDRJenkinsProdAppTaskRole${title(local.environment)}"
  policy_attachments = { task_policy = module.jenkins_task_policy_prod.policy_arn, task_policy_additional = module.jenkins_task_policy_prod_additional.policy_arn, cloudwatch_policy = module.jenkins_ecs_execution_cloudwatch_policy_prod.policy_arn, s3_policy = module.jenkins_s3_backup_policy_prod.policy_arn }
}

module "jenkins_task_policy_prod" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsTaskPolicyProd${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_task.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_task_policy_prod_additional" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsTaskPolicyAdditionalProd${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_task_prod.json.tpl", { account_id = data.aws_caller_identity.current.account_id, sandbox_account_id = data.aws_ssm_parameter.sandbox_account.value })
}

module "jenkins_backup_s3_prod" {
  source      = "./tdr-terraform-modules/s3"
  project     = "tdr"
  function    = "jenkins-backup-prod"
  common_tags = local.common_tags
}

module "jenkins_ecs_execution_cloudwatch_policy_prod" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsCloudwatchPolicyProdMgmt"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_execution_cloudwatch_prod.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_ecs_execution_role_prod" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  name               = "TDRJenkinsAppExecutionRoleProd${title(local.environment)}"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  policy_attachments = { execution_policy = module.jenkins_ecs_execution_policy_prod.policy_arn, cloudwatch_policy = module.jenkins_ecs_execution_cloudwatch_policy_prod.policy_arn }
}

module "jenkins_ecs_execution_policy_prod" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsExecutionPolicyProdMgmt"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_execution_prod.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}
