{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream",
        "ecs:UpdateContainerInstancesState",
        "ecs:Submit*",
        "ecs:StartTelemetrySession",
        "ecs:RegisterContainerInstance",
        "ecs:Poll",
        "ecs:DiscoverPollEndpoint",
        "ecs:DeregisterContainerInstance",
        "ecs:CreateCluster",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    }
  ]
}