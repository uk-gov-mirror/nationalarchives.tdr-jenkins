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
  encrypted_ami_id    = module.jenkins_ami.encrypted_ami_id
  environment         = local.environment
  jenkins_log_bucket  = module.jenkins_logs_s3.s3_bucket_id
}

module "jenkins_alb" {
  source                = "./tdr-terraform-modules/alb"
  project               = var.project
  function              = var.function
  environment           = local.environment
  alb_log_bucket        = module.jenkins_logs_s3.s3_bucket_id
  alb_security_group_id = module.jenkins.alb_security_group_id
  domain_name           = var.domain_name
  public_subnets        = module.jenkins.public_subnets
  target_id             = module.jenkins.instance_id
  vpc_id                = module.jenkins.vpc_id
  common_tags           = local.common_tags
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
  source      = "./modules/s3-publish-build-task"
}