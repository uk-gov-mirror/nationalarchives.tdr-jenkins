module "global_parameters" {
  source = "./tdr-configurations/terraform"
}

module "encryption_key" {
  source      = "./tdr-terraform-modules/kms"
  project     = var.project
  function    = "encryption"
  environment = local.environment
  common_tags = local.common_tags
  key_policy  = "message_system_access"
}

module "jenkins_ami" {
  source      = "./tdr-terraform-modules/ami"
  project     = var.project
  function    = "ecs-ec2"
  environment = local.environment
  common_tags = local.common_tags
  region      = var.default_aws_region
  kms_key_id  = module.encryption_key.kms_key_arn
  source_ami  = data.aws_ami.ecs_ami.id
}

module "jenkins" {
  source                   = "./modules/jenkins"
  alb_dns_name             = module.jenkins_alb.alb_dns_name
  alb_target_group_id      = module.jenkins_alb.alb_target_group_id
  alb_zone_id              = module.jenkins_alb.alb_zone_id
  app_name                 = "${var.project}-${var.function}"
  az_count                 = 2
  common_tags              = local.common_tags
  container_name           = var.function
  dns_zone                 = var.dns_zone
  domain_name              = var.domain_name
  ec2_instance_name        = local.ec2_instance_name
  encrypted_ami_id         = module.jenkins_ami.encrypted_ami_id
  environment              = local.environment
  ip_allowlist             = local.ip_allowlist
  jenkins_log_bucket       = module.jenkins_logs_s3.s3_bucket_id
  repository               = module.ecr_jenkins_repository.repository
  execution_role_arn       = module.jenkins_integration_execution_role.role.arn
  task_role_arn            = module.jenkins_integration_ecs_task_role.role.arn
  vpc_id                   = module.jenkins_vpc.vpc_id
  private_subnets          = module.jenkins_vpc.private_subnets
  ecs_tasks_security_group = module.jenkins_ecs_task_security_group.security_group_id
}

module "jenkins_certificate" {
  source      = "./tdr-terraform-modules/certificatemanager"
  project     = var.project
  function    = "jenkins"
  dns_zone    = var.dns_zone
  domain_name = var.domain_name
  common_tags = local.common_tags
}

module "jenkins_alb" {
  source                           = "./tdr-terraform-modules/alb"
  project                          = var.project
  function                         = var.function
  environment                      = local.environment
  alb_log_bucket                   = module.jenkins_logs_s3.s3_bucket_id
  alb_security_group_id            = module.jenkins_alb_security_group.security_group_id
  certificate_arn                  = module.jenkins_certificate.certificate_arn
  health_check_unhealthy_threshold = 5
  domain_name                      = var.domain_name
  public_subnets                   = module.jenkins_vpc.public_subnets
  target_id                        = module.jenkins_ec2.instance_id
  vpc_id                           = module.jenkins_vpc.vpc_id
  common_tags                      = local.common_tags
}

module "jenkins_logs_s3" {
  source        = "./tdr-terraform-modules/s3"
  project       = "tdr"
  function      = "jenkins-logs"
  access_logs   = false
  bucket_policy = "alb_logging_euwest2"
  common_tags   = local.common_tags
}

module "jenkins_backup_s3" {
  source      = "./tdr-terraform-modules/s3"
  project     = "tdr"
  function    = "jenkins-backup"
  common_tags = local.common_tags
}

module "sbt_with_postgres" {
  source = "./modules/sbt-with-postgres-task"
}

module "ecr_jenkins_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_integration_execution_role.role.arn }
}

module "ecr_jenkins_build_npm_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-npm"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/npm/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_npm_execution_role.role_arn }
}

module "jenkins_build_npm_execution_role" {
  source         = "./modules/build-role"
  name           = "npm"
  repository_arn = module.ecr_jenkins_build_npm_repository.repository.arn
}

module "ecr_jenkins_build_aws_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-aws"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/aws/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_aws_execution_role.role_arn }
}

module "jenkins_build_aws_execution_role" {
  source         = "./modules/build-role"
  name           = "aws"
  repository_arn = module.ecr_jenkins_build_aws_repository.repository.arn
}

module "ecr_jenkins_build_terraform_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-terraform"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/terraform/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_terraform_execution_role.role_arn }
}

module "jenkins_build_terraform_execution_role" {
  source         = "./modules/build-role"
  name           = "terraform"
  repository_arn = module.ecr_jenkins_build_terraform_repository.repository.arn
}

module "ecr_jenkins_build_transfer_frontend_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-transfer-frontend"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/transfer-frontend/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_transfer_frontend_execution_role.role_arn }
}

module "jenkins_build_transfer_frontend_execution_role" {
  source         = "./modules/build-role"
  name           = "transfer-frontend"
  repository_arn = module.ecr_jenkins_build_transfer_frontend_repository.repository.arn
}

module "ecr_jenkins_build_postgres_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-postgres"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/postgres/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_postgres_execution_role.role_arn }
}

module "jenkins_build_postgres_execution_role" {
  source         = "./modules/build-role"
  name           = "postgres"
  repository_arn = module.ecr_jenkins_build_postgres_repository.repository.arn
}

module "ecr_jenkins_build_plugin_updates_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-plugin-updates"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/plugin-updates/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_plugin_updates_execution_role.role_arn }
}

module "jenkins_build_plugin_updates_execution_role" {
  source         = "./modules/build-role"
  name           = "plugin-updates"
  repository_arn = module.ecr_jenkins_build_plugin_updates_repository.repository.arn
}

# Configure Jenkins backup using Systems Manager Maintenance Windows
module "jenkins_backup_maintenance_window" {
  source          = "./tdr-terraform-modules/ssm_maintenance_window"
  command         = "docker exec $(docker ps -aq -f ancestor=${module.ecr_jenkins_repository.repository.repository_url} -f status=running) /opt/backup.sh ${data.aws_ssm_parameter.jenkins_backup_healthcheck_url.value}"
  ec2_instance_id = module.jenkins_ec2.instance_id
  name            = "tdr-jenkins-backup-window"
  schedule        = "cron(0 0 18 ? * MON-FRI *)"
  common_tags     = local.common_tags
}

module "jenkins_maintenance_window_event" {
  source                  = "./tdr-terraform-modules/cloudwatch_events"
  event_pattern           = "jenkins_maintenance_event_window"
  lambda_event_target_arn = list(data.aws_lambda_function.notifications_function.arn)
  rule_name               = "jenkins-backup-maintenance-window"
  rule_description        = "Capture failed runs of the jenkins backup"
  event_variables         = { window_id = module.jenkins_backup_maintenance_window.window_id }
}

module "jenkins_integration_fargate_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsFargatePolicy${title(local.environment)}"
  policy_string = templatefile("./modules/jenkins/templates/jenkins_fargate_integration.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_integration_fargate_role" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  assume_role_policy = templatefile("./modules/jenkins/templates/assume_role_policy.json.tpl", { role_arn = module.jenkins_integration_ecs_task_role.role.arn })
  name               = "TDRJenkinsFargateRole${title(local.environment)}"
  policy_attachments = { fargate_policy = module.jenkins_integration_fargate_policy.policy_arn, ssm_core = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" }
}

module "jenkins_integration_ecs_task_role" {
  source             = "./tdr-terraform-modules/iam_role"
  common_tags        = local.common_tags
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  name               = "TDRJenkinsAppTaskRole${title(local.environment)}"
  policy_attachments = { task_policy = module.jenkins_integration_task_policy.policy_arn, cloudwatch_policy = module.jenkins_integration_task_cloudwatch_policy.policy_arn }
}

module "jenkins_integration_task_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsTaskPolicy${title(local.environment)}"
  policy_string = templatefile("./modules/jenkins/templates/jenkins_ecs_task_integration.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_integration_task_cloudwatch_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsCloudwatchPolicyMgmt"
  policy_string = templatefile("./modules/jenkins/templates/jenkins_ecs_task_integration_cloudwatch.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
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
  policy_string = templatefile("./modules/jenkins/templates/jenkins_ecs_execution_integration.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "jenkins_vpc" {
  source      = "./tdr-terraform-modules/vpc"
  app_name    = "tdr-jenkins"
  az_count    = 2
  common_tags = local.common_tags
  environment = local.environment
}

module "jenkins_ec2_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "jenkins_ec2_policy_${local.environment}"
  policy_string = templatefile("./modules/jenkins/templates/jenkins_ec2.json.tpl", {})
}

module "jenkins_ec2_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access within our network for the Jenkins EC2"
  name        = "tdr-jenkins-ec2-security-group-internal"
  vpc_id      = module.jenkins_vpc.vpc_id
  common_tags = local.common_tags
  ingress_security_group_rules = [
    { port = 80, security_group_id = module.jenkins_ecs_task_security_group.security_group_id, description = "Allow jenkins nodes to access the ec2 instance" },
    { port = 80, security_group_id = module.jenkins_alb_security_group.security_group_id, description = "Allows the load balancer to access the instance for health checks" },
  { port = 50000, security_group_id = module.jenkins_ecs_task_security_group.security_group_id, description : "Allows nodes to connect on port 50000" }]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "jenkins_ecs_task_security_group" {
  source            = "./tdr-terraform-modules/security_group"
  description       = "Allow outbound access only"
  name              = "mgmt-ecs-tasks-security-group"
  vpc_id            = module.jenkins_vpc.vpc_id
  common_tags       = local.common_tags
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}


module "jenkins_alb_security_group" {
  source      = "./tdr-terraform-modules/security_group"
  description = "Controls access to the Jenkins load balancer"
  name        = "tdr-jenkins-alb-security-group"
  vpc_id      = module.jenkins_vpc.vpc_id
  common_tags = local.common_tags
  ingress_cidr_rules = [
    { port = 80, cidr_blocks = local.ip_allowlist, description = "Allow trusted IPs on port 80" },
    { port = 443, cidr_blocks = local.ip_allowlist, description = "Allow trusted IPs on port 443" }
  ]
  egress_cidr_rules = [{ port = 0, cidr_blocks = ["0.0.0.0/0"], description = "Allow outbound access on all ports", protocol = "-1" }]
}

module "jenkins_ec2" {
  source              = "./tdr-terraform-modules/ec2"
  ami_id              = module.jenkins_ami.encrypted_ami_id
  common_tags         = local.common_tags
  environment         = local.environment
  name                = local.ec2_instance_name
  subnet_id           = module.jenkins_vpc.private_subnets[1]
  security_group_id   = module.jenkins_ec2_security_group.security_group_id
  attach_policies     = { ec2_policy = module.jenkins_ec2_policy.policy_arn }
  private_ip          = "10.0.1.221"
  user_data           = "user_data_jenkins_docker"
  user_data_variables = { jenkins_cluster_name = "jenkins-${local.environment}" }
  instance_type       = "t2.medium"
  volume_size         = 60
}
