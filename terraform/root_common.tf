module "global_parameters" {
  source = "./tdr-configurations/terraform"
}

module "sbt_with_postgres" {
  source            = "./tdr-terraform-modules/ecs"
  common_tags       = local.common_tags
  project           = var.project
  vpc_id            = module.jenkins_vpc.vpc_id
  sbt_with_postgres = true
}

module "plugin_updates" {
  source         = "./tdr-terraform-modules/ecs"
  common_tags    = local.common_tags
  project        = var.project
  vpc_id         = module.jenkins_vpc.vpc_id
  plugin_updates = true
}

module "npm" {
  source      = "./tdr-terraform-modules/ecs"
  common_tags = local.common_tags
  project     = var.project
  vpc_id      = module.jenkins_vpc.vpc_id
  npm         = true
}

module "encryption_key" {
  source      = "./tdr-terraform-modules/kms"
  project     = var.project
  function    = "encryption"
  environment = local.environment
  common_tags = local.common_tags
  key_policy  = "cloudwatch"
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

module "jenkins_ecr_repository" {
  source           = "./tdr-terraform-modules/ecr"
  name             = "jenkins"
  image_source_url = "https://github.com/nationalarchives/tdr-jenkins/blob/master/docker/Dockerfile"
  common_tags      = local.common_tags
  policy_name      = "jenkins_policy"
  policy_variables = { role_arn = module.jenkins_integration_execution_role.role.arn }
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
    { name = "/${local.environment}/jenkins_cluster_arn", description = "The cluster arn for the jenkins ECS cluster", type = "SecureString", value = module.jenkins_integration_ecs.jenkins_cluster_arn },
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

module "jenkins_sign_commits_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsSignCommitsPolicy"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_github_gpg_policy.json.tpl", { account_id = data.aws_caller_identity.current.account_id })
}

module "notifications_topic" {
  source      = "./tdr-terraform-modules/sns"
  common_tags = local.common_tags
  function    = "notifications"
  project     = var.project
  kms_key_arn = module.encryption_key.kms_key_arn
}

module "jenkins_cloudwatch_agent_policy" {
  source        = "./tdr-terraform-modules/iam_policy"
  name          = "TDRJenkinsCloudwatchAgentPolicyMgmt"
  policy_string = templatefile("./tdr-terraform-modules/iam_policy/templates/jenkins_cloudwatch_agent_integration.json.tpl", {})
}
