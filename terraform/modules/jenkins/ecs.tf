resource "aws_ecs_cluster" "jenkins_cluster" {
  name = "jenkins-${var.environment}"

  tags = merge(
    var.common_tags,
    map("Name", "tdr-ecs-jenkins")
  )
}

data "template_file" "jenkins_template" {
  template = file("./modules/jenkins/templates/jenkins.json.tpl")

  vars = {
    jenkins_image     = var.repository.repository_url
    container_name    = "${var.container_name}-${var.environment}"
    app_environment   = var.environment
    jenkins_log_group = aws_cloudwatch_log_group.tdr_jenkins_log_group.name
  }
}

resource "aws_ecs_task_definition" "jenkins_task" {
  family                   = "${var.container_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.api_ecs_execution.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "1024"
  memory                   = "3072"
  container_definitions    = data.template_file.jenkins_template.rendered
  task_role_arn            = aws_iam_role.api_ecs_task.arn

  volume {
    name      = "docker_bin"
    host_path = "/usr/bin/docker"
  }

  volume {
    name      = "docker_run"
    host_path = "/var/run/docker"
  }

  volume {
    name      = "docker_sock"
    host_path = "/var/run/docker.sock"
  }


  tags = merge(
    var.common_tags,
    map(
      "Name", "${var.container_name}-task-definition-${var.environment}",
    )
  )
}

resource "aws_ecs_service" "jenkins" {
  name                              = "${var.container_name}-service-${var.environment}"
  cluster                           = aws_ecs_cluster.jenkins_cluster.id
  task_definition                   = aws_ecs_task_definition.jenkins_task.arn
  desired_count                     = 1
  launch_type                       = "EC2"
  health_check_grace_period_seconds = "360"

  load_balancer {
    target_group_arn = var.alb_target_group_id
    container_name   = "${var.container_name}-${var.environment}"
    container_port   = 8080
  }
}

resource "aws_iam_role" "api_ecs_execution" {
  name               = "TDRJenkinsAppExecutionRole${title(var.environment)}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    map(
      "Name", "api-ecs-execution-iam-role-${var.environment}",
    )
  )
}

resource "aws_iam_role" "api_ecs_task" {
  name               = "TDRJenkinsAppTaskRole${title(var.environment)}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
    var.common_tags,
    map(
      "Name", "api-ecs-task-iam-role-${var.environment}",
    )
  )
}

data "aws_iam_policy_document" "ecs_assume_role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "api_ecs_task" {
  policy_arn = aws_iam_policy.api_ecs_task_policy.arn
  role       = aws_iam_role.api_ecs_task.name
}

resource "aws_iam_role_policy_attachment" "api_ecs_task_cloudwatch" {
  policy_arn = aws_iam_policy.jenkins_cloudwatch_policy.arn
  role       = aws_iam_role.api_ecs_task.name
}

resource "aws_iam_role_policy_attachment" "api_ecs_execution" {
  role       = aws_iam_role.api_ecs_execution.name
  policy_arn = aws_iam_policy.api_ecs_execution.arn
}

resource "aws_iam_role_policy_attachment" "api_ecs_execution_cloudwatch" {
  policy_arn = aws_iam_policy.jenkins_cloudwatch_policy.arn
  role       = aws_iam_role.api_ecs_execution.name
}

resource "aws_iam_policy" "api_ecs_execution" {
  name   = "TDRJenkinsExecutionPolicyMgmt"
  path   = "/"
  policy = data.aws_iam_policy_document.api_ecs_execution.json
}

data "aws_iam_policy_document" "api_ecs_execution" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = [
      aws_cloudwatch_log_group.tdr_jenkins_log_group.arn,
      var.repository.arn
    ]
  }
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "api_ecs_task_policy" {
  name   = "TDRJenkinsTaskPolicyMgmt"
  path   = "/"
  policy = data.aws_iam_policy_document.api_ecs_task_policy_document.json
}

resource "aws_iam_policy" "jenkins_cloudwatch_policy" {
  policy = data.aws_iam_policy_document.jenkins_cloudwatch_policy_document.json
  path   = "/"
  name   = "TDRJenkinsCloudwatchPolicyMgmt"
}

data aws_iam_policy_document "jenkins_cloudwatch_policy_document" {
  statement {
    actions = [
      "logs:DescribeLogGroups"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.tdr_jenkins_log_group.arn
    ]
  }
}

data "aws_iam_policy_document" "api_ecs_task_policy_document" {
  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "arn:aws:s3:::tdr-jenkins-backup-mgmt",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/staging_account",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/pr_monitor/slack/webhook",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/sonatype/passphrase",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/slack/token",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/secret_key",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/prod_account",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/management_account",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/jenkins_url",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/jenkins_master_url",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/jenkins_cluster_arn",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/intg_account",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/github/secret",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/github/jenkins-api-key",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/github/jenkins-ssh-username",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/github/jenkins-ssh-key",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/github/client",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/fargate_subnet",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/fargate_security_group",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/docker/username",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/docker/password",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/access_key",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/identitypoolid_intg",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/identitypoolid_staging",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/identitypoolid_prod",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/npm_token",
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:parameter/mgmt/ami_aws_account"
    ]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::tdr-jenkins-backup-mgmt"]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::tdr-jenkins-backup-mgmt/*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload"
    ]
    resources = [
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/yara-dependencies",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/yara-rules",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/yara",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/transfer-frontend",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/consignment-api",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/auth-server",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/file-format-build",
      "arn:aws:ecr:eu-west-2:${data.aws_caller_identity.current.account_id}:repository/consignment-export"
    ]
  }

  statement {
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "tdr_jenkins_log_group" {
  name              = "/ecs/tdr-jenkins-${var.environment}"
  retention_in_days = 30
}
