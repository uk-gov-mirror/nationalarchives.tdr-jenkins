# Jenkins prototype for TDR

All TDR documentation is available [here](https://github.com/nationalarchives/tdr-dev-documentation)

This project can be used to spin up a jenkins server using ECS. The ECS cluster is created using terraform and the jenkins configuration uses the [JCasC](https://jenkins.io/projects/jcasc/) plugin and the jenkins.yml file sets up the jenkins configuration. 

## Project components

### docker
This creates the jenkins docker image which we run as part of the ECS service. It extends the base docker image but adds the plugins.txt and jenkins.yml and runs the command to install the plugins. This is pushed to docker hub.

Each folder within the docker directory builds a Jenkins node image which is used to build some part of our infrastructure. The aws directory contains some python scripts which are used by the builds. Using python scripts makes assuming a role in the sub accounts easier than using the cli.

### terraform
This creates
* The EC2 instance for the master to run on
* The VPC and subnets
* The ECS cluster
* The ECS service
* The ECS task definition
* The security group
* The AWS SSM parameters

### terraform task modules
Some builds need a task definition with more than one container. These are defined here and then used within the Jenkins pipeline file.

## Sample job
I created the following sample pipeline job.

```
pipeline {
  agent none

  stages {
    stage('Test') {
        agent {
            ecs {
                inheritFrom 'ecs'            
            }
        }
        steps {
            sh 'echo "FROM alpine\nCMD pwd" > Dockerfile'
            stash includes: 'Dockerfile', name: 'Dockerfile'
        }
    }
    stage('Docker') {
            agent { 
                label 'master'
            }
            steps {
                unstash 'Dockerfile' 
                sh 'docker build -t alpinetest .'
                sh 'docker run alpinetest'
            }
        }
  }
}

```
For the first stage, jenkins starts a fargate task within the ecs cluster and the steps are run on that cluster. The output of these steps are stashed.

The next stage uses the master agent. The reason for this is that we want to run docker commands here and as far as I know, you can't run docker commands in an AWS fargate container. You can against the master node because although jenkins is running in a container, the docker socket is mounted into the image, allowing us to use docker from the host machine. 

I see the way forward with this would be to have a container with an environment for each specific build, e.g. sbt or node and they can be used as necessary.

## Secrets

Terraform reads the secrets from a yml file stored in a private s3 bucket. These are then used to populate the aws ssm parameter store and these in turm are used to set the environment variables in the jenkins container. 
Other projects would then use these environment variables when they need something from the secret store. This gives us a single source of truth for the secrets and means that the configuration in this or any other repo doesn't need any secrets in it. 

## Deploying

```bash
docker login -u username -p
cd docker 
docker build -t nationalarchives/jenkins .
docker push nationalarchives/jenkins

cd ../terraform
terraform apply
```

## Adding a new container

For each project which we need to build, there needs to be a docker image which Jenkins can use to build this. For example, there is a [Dockerfile](docker/sbt/Dockerfile) for sbt.  
The docker container must start with `FROM jenkins/jnlp-slave` This image is mostly stock ubuntu and from there, you need to install whatever it is you need for your build. Build the docker image and push to docker hub.

 You then need to configure another container in the clouds section of the jenkins [configuration](docker/jenkins.yml) You can copy and paste most of it, just change the name and the image.
 
 Rebuild and push the jenkins docker container and redeploy to ECS. You can then use this container in your builds. 
