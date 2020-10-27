data "aws_caller_identity" "current" {}

data "template_file" "s3_publish_template" {
  template = file("./modules/jenkins/templates/s3publish.json.tpl")

  vars = {
    account = data.aws_caller_identity.current.account_id
  }
}

resource "aws_ecs_task_definition" "s3_publish_task" {
  container_definitions    = data.template_file.s3_publish_template.rendered
  family                   = "s3publish"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsPublishRole"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildPostgresExecutionRole"
}
