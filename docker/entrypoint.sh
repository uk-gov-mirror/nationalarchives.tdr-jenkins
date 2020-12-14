#!/bin/bash

FILENAME=$(aws s3 ls s3://tdr-jenkins-backup-mgmt | awk '{print $4}' | sort -r | head -1)
# copy backup tar.gz file to var/jenkins_home directory so jenkins user has permissions to copy
aws s3 cp s3://tdr-jenkins-backup-mgmt/"$FILENAME" /var/jenkins_home/jenkins-backup.tar.gz
tar xzf /var/jenkins_home/jenkins-backup.tar.gz -C /var/jenkins_home
rm -f /var/jenkins_home/jenkins-backup.tar.gz
/sbin/tini -- /usr/local/bin/jenkins.sh
