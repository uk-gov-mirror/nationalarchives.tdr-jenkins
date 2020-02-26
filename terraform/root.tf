data "aws_s3_bucket_object" "secrets" {
  bucket = "tdr-secrets"
  key    = "${local.environment}/secrets.yml"
}

data "aws_ssm_parameter" "cost_centre" {
  name = "/mgmt/cost_centre"
}

locals {
  environment = "mgmt"
  tag_prefix  = var.tag_prefix
  aws_region  = var.default_aws_region
  common_tags = map(
    "Environment", local.environment,
    "Owner", "TDR",
    "Terraform", true,
    "CostCentre", data.aws_ssm_parameter.cost_centre.value
  )
  secrets_file_content = data.aws_s3_bucket_object.secrets.body
  secrets              = yamldecode(local.secrets_file_content)
}

terraform {
  backend "s3" {
    bucket         = "tdr-terraform-state-jenkins"
    key            = "jenkins-terraform-state"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "tdr-terraform-state-lock-jenkins"
  }
}

provider "aws" {
  region = local.aws_region
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
  environment         = local.environment
  jenkins_log_bucket  = module.jenkins_logs_s3.s3_bucket_id
  secrets             = local.secrets
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

module "sonatype_intg" {
  source      = "./modules/sonatype-build-task"
  environment = "intg"
}

module "sonatype_staging" {
  source      = "./modules/sonatype-build-task"
  environment = "staging"
}

module "sonatype_prod" {
  source      = "./modules/sonatype-build-task"
  environment = "prod"
}
