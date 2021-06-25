# Jenkins Continuous Integration server for TDR

All TDR documentation is available [here](https://github.com/nationalarchives/tdr-dev-documentation)

This project can be used to spin up a jenkins server using ECS. The ECS cluster is created using terraform and the jenkins configuration uses the [JCasC](https://jenkins.io/projects/jcasc/) plugin.

We use this project to create two Jenkins instances. For configuration:
* Integration Jenkins uses the jenkins.yml file; and
* Production Jenkins uses the jenkins-prod.yml

## Project components

### docker
This creates the jenkins docker image which we run as part of the ECS service. It extends the base docker image but adds the plugins.txt and either jenkins.yml or jenkins-prod.yml  and runs the command to install the plugins. This is pushed to AWS ECR.

Each folder within the docker directory builds a Jenkins node image which is used to build some part of our infrastructure. The aws directory contains some python scripts which are used by the builds. Using python scripts makes assuming a role in the sub accounts easier than using the cli.

### Terraform

This creates
* The EC2 instance for the master to run on
* The VPC and subnets
* The ECS cluster
* The ECS service
* The security group
* The AWS SSM parameters

#### Terraform modules

All terraform modules are in the shared tdr-terraform-modules repository. See the deployment section below.

#### Terraform task modules
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

Secrets are set manually in the aws ssm parameter store and these in turn are used to set credentials using the configuration as code plugin.

## Deployment

Before doing any Jenkins deployments:

- Warn the other developers, in case they are actively using Jenkins
- Run a manual backup - see the Backups section below. If you do not do this,
  the Jenkins job numbers and git version tags may get out of sync, which means
  you will have to [reset the Jenkins build numbers][reset-builds]

[reset-builds]: https://github.com/nationalarchives/tdr-dev-documentation/blob/master/manual/reset-jenkins-builds.md

### Deploy Jenkins Docker images

There are two Jenkins instances, integration and production, which need to be deployed but the process is similar.

First set an environment variable with the TDR management account ID, replacing
1234 with the real ID:

```bash
export MGMT_ACCOUNT=1234
```

Get credentials for the TDR management account using Single Sign On. Then log
into ECR.

```bash
cd docker
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin $MGMT_ACCOUNT.dkr.ecr.eu-west-2.amazonaws.com
```

Build and push the integration Jenkins

```bash
docker build --pull --no-cache -t $MGMT_ACCOUNT.dkr.ecr.eu-west-2.amazonaws.com/jenkins:latest .
docker push $MGMT_ACCOUNT.dkr.ecr.eu-west-2.amazonaws.com/jenkins:latest
```

Build and push the production Jenkins

```bash
docker build -f Dockerfile-prod --pull --no-cache -t $MGMT_ACCOUNT.dkr.ecr.eu-west-2.amazonaws.com/jenkins-pord:latest .
docker push $MGMT_ACCOUNT.dkr.ecr.eu-west-2.amazonaws.com/jenkins-prod:latest
```

Then redeploy Jenkins in ECS. This will cause Jenkins downtime, so check with
the rest of the team first.

First, **run a backup** to avoid resetting build numbers. See the backup
instructions below.

Then restart the Jenkins ECS container:

```bash
aws ecs update-service --force-new-deployment --cluster jenkins-mgmt \
  --service jenkins-service-mgmt --region eu-west-2
```

If this fails because there are not enough resources available on the Jenkins
EC2 instance, manually stop the current Jenkins ECS task in the AWS console. ECS
will automatically deploy a new container when the first one has stopped.

### Deploy Jenkins EC2 instance and Terraform config

#### Set up sub-projects

Clone the Terraform modules and the configurations project, which contains
sensitive information like IP addresses:

```bash
cd terraform
git clone git@github.com:nationalarchives/tdr-terraform-modules.git
git clone git@github.com:nationalarchives/tdr-configurations.git
```

If these subfolders already exist, pull the latest version of the master branch
for each one.

#### Run Terraform

```bash
cd terraform
terraform apply
```

### Deploy Jenkins node images

For each project which we need to build, there needs to be a docker image which
Jenkins can use to build this. For example, there is a
[Dockerfile](docker/sbt/Dockerfile) for sbt.

#### Update a container

Once you have changed the Dockerfile for a Jenkins node, build the image and
push it to ECR by going to the directory for the node (e.g. docker/sbt). Log
into ECR as above, then run:

  ```
  docker build -t nationalarchives/jenkins-build-<name-of-node>:latest .
  docker push nationalarchives/jenkins-build-<name-of-node>:latest
  ```

#### Add a new container

The docker container must start with `FROM jenkins/inbound-agent:alpine` This image is mostly stock Alpine Linux and from there, you need to install whatever it is you need for your build. Build the docker image and push to ECR.

You then need to configure another container in the clouds section of the jenkins [configuration](docker/jenkins.yml) You can copy and paste most of it, just change the name and the image.

Rebuild and push the jenkins docker container and redeploy to ECS. You can then use this container in your builds.

## Backups

Jenkins backups are run every weekday to save the Jenkins job configuration.

We use [AWS Systems Manager Maintenance Windows][SMMW] to schedule and configure
the backups. The Jenkins Terraform scripts in this repo configure a Bash script
which is run on the Jenkins EC2 instance on a daily schedule.

To investigate a failed or missed backup, see the [Maintenance Window history]
in the management account.

To manually initiate a backup:

- If you haven't changed the backup configuration recently, and haven't deployed
  a new EC2 instance:
  - Go the [Systems Manager Command History]
  - Find a recent successful backup
  - Open the command details and check the parameters to make sure it is for the
    Jenkins instance you want to back up. The `docker exec` command will be
    `<account>.dkr.ecr.eu-west-2.amazonaws.com/jenkins` for integration Jenkins,
    and `<account>.dkr.ecr.eu-west-2.amazonaws.com/jenkins-prod` for  production
    Jenkins.
  - At the top of the command details page, click the Rerun button
- Otherwise:
  - Go to the [Maintenance Window config][mw-config] and click Edit
  - Change the schedule so that it will run in a few minutes time. For example,
    to run the backup at 11:45, change the schedule to
    `cron(0 45 11 ? * MON-FRI *)`
  - Check the [Maintenance Window history] at the scheduled time, and check that
    the status changes to "In progress", then (after five to ten minutes) to
    "Success"
  - Change the schedule back to the original time, or run the Jenkins Terraform
    script to reset it

[SMMW]: https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-maintenance.html
[Maintenance Window history]: https://eu-west-2.console.aws.amazon.com/systems-manager/maintenance-windows/mw-0bd9ef68cfe04bd4e/history?region=eu-west-2
[Systems Manager Command History]: https://eu-west-2.console.aws.amazon.com/systems-manager/run-command/complete-commands?region=eu-west-2
[mw-config]: https://eu-west-2.console.aws.amazon.com/systems-manager/maintenance-windows/mw-0bd9ef68cfe04bd4e/description?region=eu-west-2
