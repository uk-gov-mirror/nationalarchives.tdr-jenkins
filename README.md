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

**Important Note**: tdr-jenkins uses v13 of Terraform. Ensure that Terraform v13 is installed before proceeding.

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

**Tip** It is worth updating all [plugins][plugin-updates] before proceeding, as old plugin versions can cause errors in the Jenkins startup.

#### Building and Pushing Jenkins Docker Images to ECR

There is a Jenkins job to *build* the images (deployment of updated images is a manual process): [TDR Build Jenkins Node Images][TDR Build Jenkins Node Images]

Set the following parameters to build and push the image for deployment:
* BRANCH: `master` (default value)
* ECR_REPOSITORY: `mgmt` (default value)
* JENKINS_NODE: `jenkins` or `jenkins-prod` (depends on which Jenkins instance is to be updated)

To check the whether the image has any vulnerabilities the image can be pushed to the sandbox ECR before pushing to the management ECR.

*NOTE*: Before proceeding ensure the sandbox ECR has been created. See: [TDR Scripts: ECR Sandbox][TDR Scripts: ECR Sandbox]

Set the following parameters to build and push the image to the sandbox ECR:
* BRANCH: `[name of branch with image changes]`
* ECR_REPOSITORY: `sandbox`
* JENKINS_NODE: `jenkins` or `jenkins-prod` (depends on which Jenkins instance is to be checked)

#### Deploying Updated Jenkins Images

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

[plugin-updates]: https://github.com/nationalarchives/tdr-dev-documentation/blob/master/manual/update-jenkins.md#update-the-jenkins-plugins

### Deploy Jenkins EC2 instance and Terraform config

**Important Note**: tdr-jenkins uses v1.1.3 of Terraform. Ensure that Terraform v1.1.3 is installed before proceeding.

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

There is a Jenkins job to *build* the node images: [TDR Build Jenkins Node Images][TDR Build Jenkins Node Images]

Set the following parameters to build and push the image for deployment:
* BRANCH: `master` (default value)
* ECR_REPOSITORY: `mgmt` (default value)
* JENKINS_NODE: `[select node image from drop down list]`

To check the whether the image has any vulnerabilities the image can be pushed to the sandbox ECR before pushing to the management ECR.

*NOTE*: Before proceeding ensure the sandbox ECR has been created. See: [TDR Scripts: ECR Sandbox][TDR Scripts: ECR Sandbox]

Set the following parameters to build and push the image to the sandbox ECR:
* BRANCH: `[name of branch with image changes]`
* ECR_REPOSITORY: `sandbox`
* JENKINS_NODE: `[select node image from drop down list]`

#### Periodically update the containers
We are getting a number of vulnerabilities from the regular image scan in the Jenkins node images. The solution is usually to rebuild them using the Jenkins job above. 

To try to reduce the amount of time we spend running this job, there is a new Jenkins job defined in [Jenkinsfile-scheduled-node-build](./Jenkinsfile-scheduled-node-build) 

This job runs once a week and will call the [TDR Build Jenkins Node Images][TDR Build Jenkins Node Images] job for each of the node images. We don't build the Jenkins docker images themselves as these are usually done when there are plugin updates or a new Jenkins version. 

#### Add a new container

The docker container must start with `FROM jenkins/inbound-agent:alpine` This image is mostly stock Alpine Linux and from there, you need to install whatever it is you need for your build:
* Add the new node name to the list of node names in the `Jenkinsfile-build-nodes`
* Add IAM permission for the production Jenkins ECS task role to access the ECR repository for the new image: [Prod ECS Task Role Policy][Prod ECS Task Role Policy]
* Push Git branch with new container
* Build the docker image and push to ECR using the Jenkins job, setting the `BRANCH` parameter to the branch with the new container: [TDR Build Jenkins Node Images][TDR Build Jenkins Node Images]

You then need to configure another container in the clouds section of the jenkins [configuration](docker/jenkins.yml) You can copy and paste most of it, just change the name and the image.

Rebuild and push the jenkins docker container and redeploy to ECS. You can then use this container in your builds.

[Prod ECS Task Role Policy]: https://github.com/nationalarchives/tdr-terraform-modules/blob/master/iam_policy/templates/jenkins_ecs_task_prod.json.tpl

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
[TDR Build Jenkins Node Images]: https://jenkins-prod.tdr-management.nationalarchives.gov.uk/job/TDR%20Build%20Jenkins%20Node%20Images
[TDR Scripts: ECR Sandbox]: https://github.com/nationalarchives/tdr-scripts/tree/master/terraform/ecr-sandbox
