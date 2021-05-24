#!/bin/bash

FILENAME=$(aws s3 ls s3://tdr-jenkins-backup-prod-mgmt | awk '{print $4}' | sort -r | head -1)
# copy backup tar.gz file to var/jenkins_home directory so jenkins user has permissions to copy
aws s3 cp s3://tdr-jenkins-backup-mgmt/"$FILENAME" /var/jenkins_home/jenkins-backup.tar.gz
tar xzf /var/jenkins_home/jenkins-backup.tar.gz -C /var/jenkins_home
rm -f /var/jenkins_home/jenkins-backup.tar.gz
git-secrets --register-aws --global
git-secrets --add --global '([^0-9])*[0-9]{12}([^0-9])*'
git-secrets --add --global --allowed '1234'
/sbin/tini -- /usr/local/bin/jenkins.sh
