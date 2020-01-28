[
    {
      "cpu": 1024,
      "memory": 4096,
      "image": "nationalarchives/jenkins-build-sonatype",
      "name": "sonatype",
      "taskRoleArn": "arn:aws:iam::${account}:role/TDRJenkinsPublishRole${app_environment_title_case}",
      "compatibilities": ["FARGATE"],
      "networkMode": "awsvpc"
    },
    {
      "cpu": 256,
      "environment": [
        {
          "name": "MYSQL_DATABASE",
          "value": "consignmentapi"
        },
        {
          "name": "MYSQL_ROOT_PASSWORD",
          "value": "password"
        }
      ],
      "memory": 512,
      "image": "mysql:5.7",
      "name": "mysql",
      "taskRoleArn": "arn:aws:iam::${account}:role/TDRJenkinsPublishRole${app_environment_title_case}",
      "compatibilities": ["FARGATE"],
      "networkMode": "awsvpc"
    }
]
