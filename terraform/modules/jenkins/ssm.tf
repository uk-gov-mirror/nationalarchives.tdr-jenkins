resource "aws_ssm_parameter" "access_key" {
  name        = "/${var.environment}/access_key"
  description = "The access key"
  type        = "SecureString"
  value       = var.secrets.access_key
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "secret_key" {
  name        = "/${var.environment}/secret_key"
  description = "The access key"
  type        = "SecureString"
  value       = var.secrets.secret_key
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

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


resource "aws_ssm_parameter" "github_client" {
  name        = "/${var.environment}/github/client"
  description = "The client id for the github auth integration"
  type        = "SecureString"
  value       = var.secrets.github_client
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_secret" {
  name        = "/${var.environment}/github/secret"
  description = "The client secret for the github auth integration"
  type        = "SecureString"
  value       = var.secrets.github_secret
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_ssh_username" {
  name        = "/${var.environment}/github/jenkins-ssh-username"
  description = "The username for the jenkins github user"
  type        = "SecureString"
  value       = var.secrets.github_ssh_username
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "github_ssh_key" {
  name        = "/${var.environment}/github/jenkins-ssh-key"
  description = "The SSH key for the jenkins github user"
  type        = "SecureString"
  value       = var.secrets.github_ssh_key
  overwrite   = true
  tags = {
    environment = var.environment
  }
}


resource "aws_ssm_parameter" "docker_username" {
  name        = "/${var.environment}/docker/username"
  description = "The username for the jenkins docker user"
  type        = "SecureString"
  value       = var.secrets.docker_username
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "docker_password" {
  name        = "/${var.environment}/docker/password"
  description = "The password for the jenkins docker user"
  type        = "SecureString"
  value       = var.secrets.docker_password
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "slack_token" {
  name        = "/${var.environment}/slack/token"
  description = "The token for the slack integration"
  type        = "SecureString"
  value       = var.secrets.slack_token
  overwrite   = true
  tags = {
    environment = var.environment
  }
}

resource "aws_ssm_parameter" "management_account" {
  name        = "/${var.environment}/management_account"
  description = "The management account id"
  type        = "SecureString"
  value       = data.aws_caller_identity.current.account_id
}

resource "aws_ssm_parameter" "jenkins_master_url" {
  name        = "/${var.environment}/jenkins_master_url"
  type        = "SecureString"
  description = "The internal url for the jenkins master"
  value       = "http://${aws_instance.jenkins.private_ip}"
}
