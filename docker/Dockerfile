FROM jenkins/jenkins:alpine
USER root
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false ${JAVA_OPTS:-}"
RUN apk update && \
        apk upgrade openssl && \
        apk add py3-pip zip make && \
        mkdir -p /opt/jcasc && \
        addgroup docker && \
        addgroup jenkins docker && \
        pip3 install awscli && \
        mkdir -p /var/jenkins_home/init.groovy.d && \
        git clone https://github.com/awslabs/git-secrets.git && \
        make install -C git-secrets && \
        wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/local/bin/jq && \
        chmod +x /usr/local/bin/jq

ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yml /usr/share/jenkins/ref/jenkins.yaml
# Ensure jenkins user owns files on copy
# to preserve the correct permissions on the /var/jenkins_home/plugins directory
COPY --chown=jenkins backup.sh /opt/backup.sh
COPY --chown=jenkins logging.groovy /var/jenkins_home/init.groovy.d/logging.groovy
COPY --chown=jenkins github-oauth.hpi /var/jenkins_home/plugins/
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt && chmod +x /opt/backup.sh
COPY entrypoint.sh .

USER jenkins

ENTRYPOINT ["/entrypoint.sh"]
