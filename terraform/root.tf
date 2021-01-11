module "encryption_key" {
  source      = "./tdr-terraform-modules/kms"
  project     = var.project
  function    = "encryption"
  environment = local.environment
  common_tags = local.common_tags
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
  source              = "./modules/jenkins"
  alb_dns_name        = module.jenkins_alb.alb_dns_name
  alb_target_group_id = module.jenkins_alb.alb_target_group_id
  alb_zone_id         = module.jenkins_alb.alb_zone_id
  app_name            = "${var.project}-${var.function}"
  az_count            = 2
  common_tags         = local.common_tags
  container_name      = var.function
  dns_zone            = var.dns_zone
  domain_name         = var.domain_name
  ec2_instance_name   = local.ec2_instance_name
  encrypted_ami_id    = module.jenkins_ami.encrypted_ami_id
  environment         = local.environment
  jenkins_log_bucket  = module.jenkins_logs_s3.s3_bucket_id
  repository          = module.ecr_jenkins_repository.repository
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
  alb_security_group_id            = module.jenkins.alb_security_group_id
  certificate_arn                  = module.jenkins_certificate.certificate_arn
  health_check_unhealthy_threshold = 5
  domain_name                      = var.domain_name
  public_subnets                   = module.jenkins.public_subnets
  target_id                        = module.jenkins.instance_id
  vpc_id                           = module.jenkins.vpc_id
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

module "s3_publish" {
  source = "./modules/s3-publish-build-task"
}

module "ecr_jenkins_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins.ecs_execution_role_arn }
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

# Configure Jenkins backup using Systems Manager Maintenance Windows
module "jenkins_backup_maintenance_window" {
  source          = "./tdr-terraform-modules/ssm_maintenance_window"
  command         = "docker exec $(docker ps -aq -f ancestor=${module.ecr_jenkins_repository.repository.repository_url} -f status=running) /opt/backup.sh ${data.aws_ssm_parameter.jenkins_backup_healthcheck_url.value}"
  ec2_instance_id = module.jenkins.instance_id
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
