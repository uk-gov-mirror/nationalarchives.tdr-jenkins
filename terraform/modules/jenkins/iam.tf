data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "jenkins_fargate_assume_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "jenkins_fargate_execution_policy_document" {
  statement {
    effect = "Allow"
    actions = [

    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "jenkins_fargate_policy_document" {

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "ecs:RunTask",
      "ecs:StopTask",
      "ecs:ListContainerInstances",
      "ecs:DescribeTasks",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformAssumeRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformAssumeRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformAssumeRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsPublishRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformRoleMgmt",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeReadParamsRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeReadParamsRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeReadParamsRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRCustodianAssumeRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRCustodianAssumeRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRCustodianAssumeRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsAppExecutionRoleMgmt",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsAppTaskRoleMgmt",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildNpmExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildAwsExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildTerraformExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildTransferFrontendExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildPostgresExecutionRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRScriptsTerraformRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRScriptsTerraformRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRScriptsTerraformRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeLambdaRoleMgmt",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeS3ExportRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeS3ExportRoleStaging",
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:task-definition/*:*",
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:cluster/${aws_ecs_cluster.jenkins_cluster.name}",
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:task/*",
      "arn:aws:s3:::tdr-staging-mgmt/*",
      "arn:aws:s3:::tdr-staging-mgmt",
      "arn:aws:s3:::tdr-releases-mgmt/*",
      "arn:aws:s3:::tdr-releases-mgmt"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "jenkins_fargate_policy" {
  name   = "TDRJenkinsFargatePolicy${title(var.environment)}"
  path   = "/"
  policy = data.aws_iam_policy_document.jenkins_fargate_policy_document.json
}

resource "aws_iam_group" jenkins_fargate_group {
  name = "jenkins-fargate-${var.environment}"
}

resource "aws_iam_group_policy_attachment" "jenkins_fargate_policy_attachment" {
  group      = aws_iam_group.jenkins_fargate_group.name
  policy_arn = aws_iam_policy.jenkins_fargate_policy.arn
}

data "aws_iam_policy_document" "fargate_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "jenkins_ecs_role" {
  assume_role_policy = templatefile("${path.module}/templates/assume_role_policy.json.tpl", { role_arn = aws_iam_role.api_ecs_task.arn })
  name               = "TDRJenkinsFargateRole${title(var.environment)}"
}

resource "aws_iam_role_policy_attachment" "jenkins_ecs_role_attach" {
  policy_arn = aws_iam_policy.jenkins_fargate_policy.arn
  role       = aws_iam_role.jenkins_ecs_role.id
}
