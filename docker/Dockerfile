FROM jenkins/jenkins:alpine
USER root
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false ${JAVA_OPTS:-}"
RUN apk update && \
        apk add py3-pip zip make && \
        mkdir -p /opt/jcasc && \
        addgroup docker && \
        addgroup jenkins docker && \
        pip3 install awscli && \
        mkdir -p /var/jenkins_home/init.groovy.d && \
        git clone https://github.com/awslabs/git-secrets.git && \
        make install -C git-secrets && \
        git-secrets --register-aws --global && \
#       Additional git secrets rule to check for AWS account numbers (any set of 12 digits)
        git-secrets --add --global '([^0-9])*[0-9]{12}([^0-9])*' && \
#       Additional git secrets exclusion rule to allow dummy AWS account number 1234 for documentation
        git-secrets --add --global --allowed '1234'

ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yml /usr/share/jenkins/ref/jenkins.yaml
COPY backup.sh /opt/backup.sh
COPY logging.groovy /var/jenkins_home/init.groovy.d/logging.groovy
COPY github-oauth.hpi /var/jenkins_home/plugins/
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt && chmod +x /opt/backup.sh
COPY entrypoint.sh .

USER jenkins

ENTRYPOINT ["/entrypoint.sh"]
