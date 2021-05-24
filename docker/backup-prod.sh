#!/bin/bash

curl $1/start
tar -zcf - -C /var/jenkins_home jobs | aws s3 cp - s3://tdr-jenkins-backup-prod-mgmt/jenkins-backup-`date +"%Y-%m-%d:%H:%M"`.tar.gz
curl $1
