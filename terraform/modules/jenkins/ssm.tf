resource "aws_ssm_parameter" "access_key" {
  name        = "/${var.environment}/access_key"
  description = "The access key"
  type        = "String"
  value       = var.secrets.access_key
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "secret_key" {
  name        = "/${var.environment}/secret_key"
  description = "The access key"
  type        = "String"
  value       = var.secrets.secret_key
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "integration_terraform_access_key" {
  name        = "/${var.environment}/integration_terraform_access_key"
  description = "The access key to create the environment"
  type        = "String"
  value       = var.secrets.integration_terraform_access_key
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "integration_terraform_secret_key" {
  name        = "/${var.environment}/integration_terraform_secret_key"
  description = "The secret key to create the environment"
  type        = "String"
  value       = var.secrets.integration_terraform_secret_key
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "jenkins_url" {
  name        = "/${var.environment}/jenkins_url"
  description = "The url for the jenkins server"
  type        = "String"
  value       = "http://${aws_alb.main.dns_name}"
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "fargate_security_group" {
  name        = "/${var.environment}/fargate_security_group"
  description = "The security group for the fargate jenkins slaves"
  type        = "String"
  value       = aws_security_group.ecs_tasks.id
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_client" {
  name        = "/${var.environment}/github/client"
  description = "The client id for the github auth integration"
  type        = "String"
  value       = var.secrets.github_client
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_secret" {
  name        = "/${var.environment}/github/secret"
  description = "The client secret for the github auth integration"
  type        = "String"
  value       = var.secrets.github_secret
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_username" {
  name        = "/${var.environment}/github/username"
  description = "The username for the jenkins github webhook"
  type        = "String"
  value       = var.secrets.github_username
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_password" {
  name        = "/${var.environment}/github/password"
  description = "The password for the jenkins github webhook"
  type        = "String"
  value       = var.secrets.github_password
  overwrite = true
  tags = {
    environment = var.environment
  }
}


resource "aws_ssm_parameter" "docker_username" {
  name        = "/${var.environment}/docker/username"
  description = "The username for the jenkins docker user"
  type        = "String"
  value       = var.secrets.docker_username
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "docker_password" {
  name        = "/${var.environment}/docker/password"
  description = "The password for the jenkins docker user"
  type        = "String"
  value       = var.secrets.docker_password
  overwrite = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "slack_token" {
  name        = "/${var.environment}/slack/token"
  description = "The token for the slack integration"
  type        = "String"
  value       = var.secrets.slack_token
  overwrite = true
  tags = {
    environment = var.environment
  }
}
