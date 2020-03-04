pipeline {
  agent {
    label "master"
  }
  stages {
    stage("Zip jobs directory and upload") {
        agent {
            label "master"
        }
        steps {
            script {
                sh "tar -zcf jenkins-backup.tar.gz -C /var/jenkins_home/ jobs"
                sh 'aws s3 cp jenkins-backup.tar.gz s3://tdr-jenkins-backup-mgmt/jenkins-backup-`date +"%Y-%m-%d:%H:%M"`.tar.gz'
            }
        }
    }
  }
}