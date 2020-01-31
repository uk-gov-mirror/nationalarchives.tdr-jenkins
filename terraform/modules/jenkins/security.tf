resource "aws_security_group" "ec2_internal" {
  name        = "${var.app_name}-ec2-security-group-internal"
  description = "Controls access within our network for the Jenkins EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.jenkins_alb_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  # 50000 is the port which allows the nodes to connect to the parent
  ingress {
    protocol        = "tcp"
    from_port       = 50000
    to_port         = 50000
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "external_ips" {
  name = "/${var.environment}/external_ips"
}

resource "aws_security_group" "jenkins_alb_group" {
  name        = "${var.app_name}-alb-security-group"
  description = "Controls access to the Jenkins load balancer"
  vpc_id      = aws_vpc.main.id
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = split(",", data.aws_ssm_parameter.external_ips.value)
  }

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = split(",", data.aws_ssm_parameter.external_ips.value)
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-ecs-tasks-security-group"
  description = "Allow outbound access only"
  vpc_id      = aws_vpc.main.id

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.environment}-ecs-task-security-group")
  )
}

