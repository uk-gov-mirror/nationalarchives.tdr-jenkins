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
  execution_role_arn       = var.execution_role_arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "1024"
  memory                   = "3072"
  container_definitions    = data.template_file.jenkins_template.rendered
  task_role_arn            = var.task_role_arn

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


# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "tdr_jenkins_log_group" {
  name              = "/ecs/tdr-jenkins-${var.environment}"
  retention_in_days = 30
}
