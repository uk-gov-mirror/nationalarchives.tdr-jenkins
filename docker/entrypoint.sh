#!/bin/bash

FILENAME=$(aws s3 ls s3://tdr-jenkins-backup-mgmt | awk '{print $4}' | sort -r | head -1)
aws s3 cp s3://tdr-jenkins-backup-mgmt/"$FILENAME" jenkins-backup.tar.gz
tar xzf jenkins-backup.tar.gz -C /var/jenkins_home
/sbin/tini -- /usr/local/bin/jenkins.sh