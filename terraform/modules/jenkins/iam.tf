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
      "ecs:DescribeTasks"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRoleProd",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformRoleIntg",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformRoleStaging",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRTerraformRoleProd",
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:task-definition/*:*",
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:cluster/${aws_ecs_cluster.jenkins_cluster.name}",
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:task/*"
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
  group = aws_iam_group.jenkins_fargate_group.name
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
