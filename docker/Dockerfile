FROM jenkins/jenkins:lts
USER root
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false ${JAVA_OPTS:-}"
RUN apt-get update && \
        apt-key update && \
        apt-get install -y libltdl7 && \
        mkdir -p /opt/jcasc && \
        groupadd docker && \
        usermod -G docker jenkins
ENV CASC_JENKINS_CONFIG /usr/share/jenkins/ref/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY jenkins.yml /usr/share/jenkins/ref/jenkins.yaml
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
