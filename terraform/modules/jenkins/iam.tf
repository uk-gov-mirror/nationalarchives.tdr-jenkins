resource "aws_iam_role" "jenkins_fargate_role" {
  name = "jenkins_fargate_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.jenkins_fargate_assume_role.json
  tags = merge(
  var.common_tags,
  map(
  "Name", "jenkins-fargate-iam-role-${var.environment}",
  )
  )
}

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

data "aws_iam_policy_document" "jenkins_fargate_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:ListClusters",
      "ecs:DescribeContainerInstances",
      "ecs:ListTaskDefinitions",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:ListContainerInstances",
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:cluster/${aws_ecs_cluster.jenkins_cluster.name}",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsNodeRole"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask"
    ]
    resources = [
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:task-definition/*:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:StopTask",
      "ecs:DescribeTasks"
    ]
    resources = [
      "arn:aws:ecs:eu-west-2:${data.aws_caller_identity.current.account_id}:task/*"
    ]
  }

}

resource "aws_iam_policy" "jenkins_fargate_policy" {
  name   = "jenkins_fargate_policy_${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.jenkins_fargate_policy_document.json
}

resource "aws_iam_role_policy_attachment" "fargate_task_attach" {
  role       = aws_iam_role.jenkins_fargate_role.name
  policy_arn = aws_iam_policy.jenkins_fargate_policy.arn
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
