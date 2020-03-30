resource "aws_ssm_parameter" "jenkins_url" {
  name        = "/${var.environment}/jenkins_url"
  description = "The url for the jenkins server"
  type        = "SecureString"
  value       = "http://${var.alb_dns_name}"
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "jenkins_cluster_arn" {
  name        = "/${var.environment}/jenkins_cluster_arn"
  description = "The cluster arn for the jenkins ECS cluster"
  type        = "SecureString"
  value       = aws_ecs_cluster.jenkins_cluster.arn
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "fargate_security_group" {
  name        = "/${var.environment}/fargate_security_group"
  description = "The security group for the fargate jenkins slaves"
  type        = "SecureString"
  value       = aws_security_group.ecs_tasks.id
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "fargate_subnet" {
  name        = "/${var.environment}/fargate_subnet"
  description = "The subnet for the fargate jenkins slaves"
  type        = "SecureString"
  value       = aws_subnet.private[0].id
  overwrite   = true
  tags = {
    environment = var.environment
  }
}


