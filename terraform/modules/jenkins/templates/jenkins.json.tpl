[
      {
        "name": "${container_name}",
        "image": "${jenkins_image}",
        "cpu": 0,
        "portMappings": [
          {
            "containerPort": 8080,
            "hostPort": 80,
            "protocol": "tcp"
          },
          {
            "containerPort": 50000,
            "hostPort": 50000,
            "protocol": "tcp"
          }
        ],
        "essential": true,
        "secrets": [
          {
            "name": "ACCESS_KEY",
            "valueFrom": "/${app_environment}/access_key"
          },
          {
            "name": "SECRET_KEY",
            "valueFrom": "/${app_environment}/secret_key"
          },
          {
            "name": "JENKINS_URL",
            "valueFrom" : "/${app_environment}/jenkins_url"
          },
          {
            "name": "FARGATE_SECURITY_GROUP",
            "valueFrom" : "/${app_environment}/fargate_security_group"
          },
          {
            "name": "GITHUB_CLIENT",
            "valueFrom" : "/${app_environment}/github/client"
          },
          {
            "name": "GITHUB_SECRET",
            "valueFrom" : "/${app_environment}/github/secret"
          },
          {
            "name": "GITHUB_USERNAME",
            "valueFrom" : "/${app_environment}/github/username"
          },
          {
            "name": "GITHUB_PASSWORD",
            "valueFrom" : "/${app_environment}/github/password"
          },
          {
            "name": "DOCKER_USERNAME",
            "valueFrom" : "/${app_environment}/docker/username"
          },
          {
            "name": "DOCKER_PASSWORD",
            "valueFrom" : "/${app_environment}/docker/password"
          },
          {
            "name": "SLACK_TOKEN",
            "valueFrom" : "/${app_environment}/slack/token"
          },
          {
            "name": "INTEGRATION_TERRAFORM_ACCESS_KEY",
            "valueFrom" : "/${app_environment}/integration_terraform_access_key"
          },
          {
            "name": "INTEGRATION_TERRAFORM_SECRET_KEY",
            "valueFrom": "/${app_environment}/integration_terraform_secret_key"
          },
          {
            "name": "INTEGRATION_ACCOUNT",
            "valueFrom": "/mgmt/intg_account"
          },
          {
            "name": "STAGING_ACCOUNT",
            "valueFrom": "/mgmt/staging_account"
          },
          {
            "name": "PROD_ACCOUNT",
            "valueFrom": "/mgmt/prod_account"
          }
        ],
        "environment": [
          {
            "name": "JENKINS_CLUSTER",
            "value" : "${cluster_arn}"
          },
          {
            "name": "FARGATE_SUBNET",
            "value": "${fargate_subnet}"
          },
          {
            "name": "LOAD_BALANCER_URL",
            "value": "${load_balancer_url}"
          }
        ],
        "mountPoints": [
          {
            "sourceVolume": "jenkins",
            "containerPath": "/var/jenkins_home"
          },
          {
            "sourceVolume": "docker_bin",
            "containerPath": "/usr/bin/docker"
          },
          {
            "sourceVolume": "docker_run",
            "containerPath": "/var/run/docker"
          },
          {
            "sourceVolume": "docker_sock",
            "containerPath": "/var/run/docker.sock"
          }
        ],
        "volumesFrom": []
      }
    ]
