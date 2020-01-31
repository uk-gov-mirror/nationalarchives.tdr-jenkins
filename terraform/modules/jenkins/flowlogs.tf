resource "aws_flow_log" "jenkins_flowlog" {
  iam_role_arn    = aws_iam_role.jenkins_flowlog_role.arn
  log_destination = aws_cloudwatch_log_group.jenkins_flowlog_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}

resource "aws_cloudwatch_log_group" "jenkins_flowlog_log_group" {
  name = "/flowlogs/tdr-jenkins-vpc-${var.environment}"
}

resource "aws_iam_role" "jenkins_flowlog_role" {
  name = "jenkins_flowlog_role_${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jenkins_flowlog_policy" {
  name = "jenkins_flowlog_policy_${var.environment}"
  role = aws_iam_role.jenkins_flowlog_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}