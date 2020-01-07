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
