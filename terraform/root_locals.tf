locals {
  environment = "mgmt"
  tag_prefix  = var.tag_prefix
  aws_region  = var.default_aws_region
  common_tags = map(
    "Environment", local.environment,
    "Owner", "TDR",
    "Terraform", true,
    "TerraformSource", "https://github.com/nationalarchives/tdr-jenkins/tree/master/terraform",
    "CostCentre", data.aws_ssm_parameter.cost_centre.value
  )
  ec2_instance_name = "JenkinsTaskDefinition"

  developer_ip_list = split(",", module.global_parameters.developer_ips)
  trusted_ip_list   = split(",", module.global_parameters.trusted_ips)
  ip_allowlist      = concat(local.developer_ip_list, local.trusted_ip_list)
}
