FROM jenkins/jenkins:lts
USER root
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false ${JAVA_OPTS:-}"
RUN apt-get update && \
        apt-key update && \
        apt-get install -y libltdl7 python3-pip && \
        mkdir -p /opt/jcasc && \
        groupadd docker && \
        usermod -G docker jenkins && \
        pip3 install awscli && \
        mkdir -p /var/jenkins_home/init.groovy.d && \
        git clone https://github.com/awslabs/git-secrets.git && \
        make install -C git-secrets && \
        git-secrets --register-aws --global

ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yml /usr/share/jenkins/ref/jenkins.yaml
COPY logging.groovy /var/jenkins_home/init.groovy.d/logging.groovy
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
COPY entrypoint.sh .
ENTRYPOINT ["/entrypoint.sh"]
