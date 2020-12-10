#!/bin/bash

curl $1/start
tar -zcf /var/jenkins_home/jenkins-backup.tar.gz -C /var/jenkins_home jobs
aws s3 cp /var/jenkins_home/jenkins-backup.tar.gz s3://tdr-jenkins-backup-mgmt/jenkins-backup-`date +"%Y-%m-%d:%H:%M"`.tar.gz
rm -f /var/jenkins_home/jenkins-backup.tar.gz
curl $1

