data "aws_s3_bucket_object" "secrets" {
  bucket = "tdr-secrets"
  key    = "${local.environment}/secrets.yml"
}

data "aws_ssm_parameter" "cost_centre" {
  name = "/mgmt/cost_centre"
}

data "aws_ami" "ecs_ami" {
  owners      = ["591542846629"]
  name_regex  = "^amzn2-ami-ecs-hvm-2.0.\\d{8}-x86_64-ebs"
  most_recent = true
}