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
}