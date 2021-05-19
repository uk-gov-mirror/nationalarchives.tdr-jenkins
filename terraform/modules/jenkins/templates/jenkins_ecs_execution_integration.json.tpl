{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": [
        "arn:aws:logs:eu-west-2:${account_id}:log-group:/ecs/tdr-jenkins-mgmt:*",
        "arn:aws:ecr:eu-west-2:${account_id}:repository/jenkins"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}