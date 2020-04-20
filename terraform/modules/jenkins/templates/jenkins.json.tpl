[
      {
        "name": "${container_name}",
        "image": "${jenkins_image}",
        "cpu": 0,
        "logConfiguration": {
          "logDriver": "awslogs",
          "secretOptions": null,
          "options": {
            "awslogs-group": "${jenkins_log_group}",
            "awslogs-region": "eu-west-2"
          }
        },
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
        "mountPoints": [
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
