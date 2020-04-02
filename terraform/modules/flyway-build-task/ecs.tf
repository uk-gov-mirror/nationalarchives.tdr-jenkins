data "aws_caller_identity" "current" {}

data "template_file" "flyway_template" {
  template = file("./modules/jenkins/templates/flyway.json.tpl")

  vars = {
    app_environment            = var.environment
    app_environment_title_case = title(var.environment)
    account                    = data.aws_caller_identity.current.account_id
  }
}

resource "aws_ecs_task_definition" "flyway_task" {
  container_definitions    = data.template_file.flyway_template.rendered
  family                   = "flyway-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsPublishRole${title(var.environment)}"
}