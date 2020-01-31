resource "aws_alb" "main" {
  name            = "tdr-jenkins-load-balancer-${var.environment}"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.jenkins_alb_group.id]
  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-loadbalancer")
  )
}

resource "random_string" "alb_prefix" {
  length  = 4
  upper   = false
  special = false
}

resource "aws_alb_target_group_attachment" "jenkins_target_attachment" {
  target_group_arn = aws_alb_target_group.jenkins.arn
  target_id        = aws_instance.jenkins.id
}

resource "aws_alb_target_group" "jenkins" {
  name     = "jenkins-target-group-${random_string.alb_prefix.result}-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "301,200,403"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = merge(
    var.common_tags,
    map("Name", "${var.app_name}-target-group")
  )
}

data "aws_acm_certificate" "national_archives" {
  domain   = "jenkins.tdr-management.nationalarchives.gov.uk"
  statuses = ["ISSUED"]
}

resource "aws_alb_listener" "jenkins" {
  load_balancer_arn = aws_alb.main.id
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.national_archives.arn

  default_action {
    target_group_arn = aws_alb_target_group.jenkins.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "jenkins_http" {
  load_balancer_arn = aws_alb.main.id
  port              = 80
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
