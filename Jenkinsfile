library("tdr-jenkinslib")
def repo = "tdr-jenkins"

pipeline {
  agent {
    label "master"
  }
  stages {
    stage("Run git secrets") {
      steps {
        script {
          tdr.runGitSecrets(repo)
        }
      }
    }
    stage("Zip jobs directory and upload") {
        steps {
            script {
                dir("/tmp") {
                    // Clean up old backups
                    sh "rm -rf jobs jenkins-backup.tar.gz"
                    // Copy jobs folder
                    sh "cp -R /var/jenkins_home/jobs ."
                    // Delete the current build so it doesn't show as running when Jenkins restores
                    sh "rm -rf jobs/TDR\\ Jenkins\\ Backup/builds/$BUILD_NUMBER"
                    sh "tar -zcf jenkins-backup.tar.gz jobs"
                    sh 'aws s3 cp jenkins-backup.tar.gz s3://tdr-jenkins-backup-mgmt/jenkins-backup-`date +"%Y-%m-%d:%H:%M"`.tar.gz'
                }

            }
        }
    }
  }
   post {
          failure {
              script {
                  tdr.postToDaTdrSlackChannel(colour: "danger", message: "*Transfer frontend* :jenkins-fail: The Jenkins backup has failed")
              }
          }
   }
}
