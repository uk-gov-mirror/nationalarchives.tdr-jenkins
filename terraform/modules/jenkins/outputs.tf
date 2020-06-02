output alb_security_group_id {
  value = aws_security_group.jenkins_alb_group.id
}

output instance_id {
  value = aws_instance.jenkins.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.jenkins_flowlog_log_group.name
}