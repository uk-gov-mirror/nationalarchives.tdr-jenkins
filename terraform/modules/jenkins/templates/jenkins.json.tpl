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
          },
          {
            "name": "MANAGEMENT_ACCOUNT",
            "value": "${management_account}"
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
