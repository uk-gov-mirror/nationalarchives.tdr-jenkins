data "aws_s3_bucket_object" "secrets" {
  bucket = "tdr-secrets"
  key    = "${local.environment}/secrets.yml"
}

data "aws_ssm_parameter" "cost_centre" {
  name = "/mgmt/cost_centre"
}

locals {
  #Ensure that developers' workspaces always default to 'dev'
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
  source         = "./modules/jenkins"
  common_tags    = local.common_tags
  environment    = local.environment
  app_name       = "tdr-jenkins"
  container_name = "jenkins"
  az_count       = 2
  secrets        = local.secrets
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
