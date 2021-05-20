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

module "ecr_jenkins_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_integration_execution_role.role.arn }
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
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecs_task_integration.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
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

module "ecr_jenkins_build_npm_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-npm"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/npm/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_npm_execution_role.role.arn }
}

module "jenkins_build_npm_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsBuildNpmExecutionPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecr_policy.json.tpl", { repository_arn = module.ecr_jenkins_build_npm_repository.repository.arn })
}

module "jenkins_build_npm_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRJenkinsBuildNpmExecutionRole"
  policy_attachments = { ecr_policy = module.jenkins_build_npm_execution_policy.policy_arn }
}

module "ecr_jenkins_build_aws_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-aws"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/aws/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_aws_execution_role.role.arn }
}

module "jenkins_build_aws_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsBuildAwsExecutionPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecr_policy.json.tpl", { repository_arn = module.ecr_jenkins_build_aws_repository.repository.arn })
}

module "jenkins_build_aws_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRJenkinsBuildAwsExecutionRole"
  policy_attachments = { ecr_policy = module.jenkins_build_aws_execution_policy.policy_arn }
}

module "ecr_jenkins_build_terraform_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-terraform"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/terraform/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_terraform_execution_role.role.arn }
}

module "jenkins_build_terraform_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsBuildTerraformExecutionPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecr_policy.json.tpl", { repository_arn = module.ecr_jenkins_build_terraform_repository.repository.arn })
}

module "jenkins_build_terraform_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRJenkinsBuildTerraformExecutionRole"
  policy_attachments = { ecr_policy = module.jenkins_build_terraform_execution_policy.policy_arn }
}

module "ecr_jenkins_build_transfer_frontend_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-transfer-frontend"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/transfer-frontend/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_transfer_frontend_execution_role.role.arn }
}

module "jenkins_build_transfer_frontend_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsBuildTransferFrontendExecutionPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecr_policy.json.tpl", { repository_arn = module.ecr_jenkins_build_transfer_frontend_repository.repository.arn })
}

module "jenkins_build_transfer_frontend_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRJenkinsBuildTransferFrontendExecutionRole"
  policy_attachments = { ecr_policy = module.jenkins_build_transfer_frontend_execution_policy.policy_arn }
}

module "ecr_jenkins_build_postgres_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-postgres"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/postgres/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_postgres_execution_role.role.arn }
}

module "jenkins_build_postgres_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsBuildPostgresExecutionPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecr_policy.json.tpl", { repository_arn = module.ecr_jenkins_build_postgres_repository.repository.arn })
}

module "jenkins_build_postgres_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRJenkinsBuildPostgresExecutionRole"
  policy_attachments = { ecr_policy = module.jenkins_build_postgres_execution_policy.policy_arn }
}

module "ecr_jenkins_build_plugin_updates_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins-build-plugin-updates"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/plugin-updates/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_build_plugin_updates_execution_role.role.arn }
}

module "jenkins_build_plugin_updates_execution_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsBuildPluginUpdatesExecutionPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ecr_policy.json.tpl", { repository_arn = module.ecr_jenkins_build_plugin_updates_repository.repository.arn })
}

module "jenkins_build_plugin_updates_execution_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/ecs/templates/ecs_assume_role_policy.json.tpl", {})
  common_tags        = local.common_tags
  name               = "TDRJenkinsBuildPluginUpdatesExecutionRole"
  policy_attachments = { ecr_policy = module.jenkins_build_plugin_updates_execution_policy.policy_arn }
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
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_ec2.json.tpl", {})
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

module "jenkins_common_ssm_parameters" {
  source      = "./tdr-terraform-modules/ssm_parameter"
  common_tags = local.common_tags
  parameters = [
    { name = "/${local.environment}/jenkins_cluster_arn", description = "The cluster arn for the jenkins ECS cluster", type = "SecureString", value = module.jenkins_ecs.jenkins_cluster_arn },
    { name = "/${local.environment}/fargate_security_group", description = "The security group for the fargate jenkins nodes", type = "SecureString", value = module.jenkins_ecs_task_security_group.security_group_id },
    { name = "/${local.environment}/fargate_subnet", description = "The subnet for the fargate jenkins nodes", type = "SecureString", value = module.jenkins_vpc.private_subnets[1] }
  ]
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

module "jenkins_flow_log_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsFlowlogPolicy${title(local.environment)}"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_vpc_flow_logs.json.tpl", {})
}

module "jenkins_flow_log_role" {
  source             = "./tdr-terraform-modules/iam_role"
  assume_role_policy = templatefile("./tdr-terraform-modules/iam_policy/templates/flow_logs_assume_role.json.tpl", {})
  common_tags        = local.common_tags
  name               = "jenkins_flowlog_role_${local.environment}"
  policy_attachments = { flow_log_policy = module.jenkins_flow_log_policy.policy_arn }
}

module "jenkins_flow_logs_cloudwatch_group" {
  source      = "./tdr-terraform-modules/cloudwatch_logs"
  common_tags = local.common_tags
  name        = "/flowlogs/tdr-jenkins-vpc-${local.environment}"
}

module "jenkins_flow_logs" {
  source        = "./tdr-terraform-modules/flowlogs"
  log_group_arn = module.jenkins_flow_logs_cloudwatch_group.log_group_arn
  role_arn      = module.jenkins_flow_log_role.role.arn
  s3_arn        = "arn:aws:s3:::tdr-log-data-mgmt/flowlogs/${local.environment}/jenkins/"
  vpc_id        = module.jenkins_vpc.vpc_id
}
