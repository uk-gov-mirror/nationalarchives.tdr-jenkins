#!/bin/bash

rm -rf jobs jenkins-backup.tar.gz
cp -R /var/jenkins_home/jobs .
tar -zcf jenkins-backup.tar.gz jobs
aws s3 cp jenkins-backup.tar.gz s3://tdr-jenkins-backup-mgmt/jenkins-backup-`date +"%Y-%m-%d:%H:%M"`.tar.gz