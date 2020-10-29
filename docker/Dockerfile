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
        git-secrets --add --global '([^0-9])*[0-9]{12}([^0-9])*' && \
        git-secrets --add --global -a '([^0-9])*012345678912([^0-9])*'

ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yml /usr/share/jenkins/ref/jenkins.yaml
COPY backup.sh /opt/backup.sh
COPY logging.groovy /var/jenkins_home/init.groovy.d/logging.groovy
COPY github-oauth.hpi /var/jenkins_home/plugins/
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt && chmod +x /opt/backup.sh
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
