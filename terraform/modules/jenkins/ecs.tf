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
    jenkins_image = "docker.io/nationalarchives/jenkins:${var.environment}"
    container_name = "${var.container_name}-${var.environment}"
    app_environment = var.environment
    cluster_arn = aws_ecs_cluster.jenkins_cluster.arn
    fargate_subnet = aws_subnet.private[0].id
    load_balancer_url = "http://${aws_alb.main.dns_name}"
  }
}

resource "aws_ecs_task_definition" "jenkins_task" {
  family                   = "${var.container_name}-${var.environment}"
  execution_role_arn       = aws_iam_role.api_ecs_execution.arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "1024"
  container_definitions    = data.template_file.jenkins_template.rendered
  task_role_arn            = aws_iam_role.api_ecs_task.arn

  volume {
    name      = "jenkins"
    host_path = "/var/lib/docker/volumes/ecs-jenkins"
  }

  volume {
    name = "docker_bin"
    host_path = "/usr/bin/docker"
  }

  volume {
    name = "docker_run"
    host_path = "/var/run/docker"
  }

  volume {
    name = "docker_sock"
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
    target_group_arn = aws_alb_target_group.jenkins.id
    container_name   = "${var.container_name}-${var.environment}"
    container_port   = 8080
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.jenkins_api.id
    container_name = "${var.container_name}-${var.environment}"
    container_port = 50000
  }

  depends_on = [aws_alb_listener.jenkins, aws_alb_listener.jenkins_50000]
}

resource "aws_iam_role" "api_ecs_execution" {
  name = "api_ecs_execution_role_${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  tags = merge(
  var.common_tags,
  map(
  "Name", "api-ecs-execution-iam-role-${var.environment}",
  )
  )
}

resource "aws_iam_role" "api_ecs_task" {
  name = "api_ecs_task_role_${var.environment}"
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
    actions   = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "api_ecs_execution_ssm" {
  role       = aws_iam_role.api_ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "api_ecs_execution" {
  role       = aws_iam_role.api_ecs_execution.name
  policy_arn = aws_iam_policy.api_ecs_execution.arn
}

resource "aws_iam_policy" "api_ecs_execution" {
  name   = "api_ecs_execution_policy_${var.environment}"
  path   = "/"
  policy = data.aws_iam_policy_document.api_ecs_execution.json
}

data "aws_iam_policy_document" "api_ecs_execution" {
  statement {
    actions   = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [aws_cloudwatch_log_group.tdr_jenkins_log_group.arn]
  }
}

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "tdr_jenkins_log_group" {
  name              = "/ecs/tdr-jenkins-${var.environment}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "tdr_application_log_stream" {
  name           = "tdr-jenkins-log-stream-${var.environment}"
  log_group_name = aws_cloudwatch_log_group.tdr_jenkins_log_group.name
}