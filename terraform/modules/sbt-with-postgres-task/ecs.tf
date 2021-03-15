data "aws_caller_identity" "current" {}

data "template_file" "sbt_with_postgres_template" {
  template = file("./modules/jenkins/templates/s3publish.json.tpl")

  vars = {
    account = data.aws_caller_identity.current.account_id
  }
}

resource "aws_ecs_task_definition" "sbt_with_postgres_task" {
  container_definitions    = data.template_file.sbt_with_postgres_template.rendered
  family                   = "sbtwithpostgres"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048"
  memory                   = "4096"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsPublishRole"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TDRJenkinsBuildPostgresExecutionRole"
}
