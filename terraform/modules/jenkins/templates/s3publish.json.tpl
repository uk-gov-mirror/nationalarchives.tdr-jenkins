[
    {
      "cpu": 1024,
      "memory": 4096,
      "image": "${account}.dkr.ecr.eu-west-2.amazonaws.com/jenkins-build-postgres",
      "name": "sbtwithpostgres",
      "taskRoleArn": "arn:aws:iam::${account}:role/TDRJenkinsPublishRole",
      "compatibilities": ["FARGATE"],
      "networkMode": "awsvpc"
    },
    {
      "cpu": 256,
      "environment": [
        {
          "name": "POSTGRES_USER",
          "value": "tdr"
        },
        {
          "name": "POSTGRES_DB",
          "value": "consignmentapi"
        },
        {
          "name": "POSTGRES_PASSWORD",
          "value": "password"
        }
      ],
      "memory": 512,
      "image": "postgres:11.6",
      "name": "postgres",
      "taskRoleArn": "arn:aws:iam::${account}:role/TDRJenkinsPublishRole",
      "compatibilities": ["FARGATE"],
      "networkMode": "awsvpc"
    }
]
