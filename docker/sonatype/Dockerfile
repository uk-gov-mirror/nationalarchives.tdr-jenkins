FROM jenkins/jnlp-slave
USER root 
RUN apt-get update && \
        apt-get install -y apt-transport-https python3-pip && \
        echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list && \
        apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
        apt-get update && \
        apt-get install sbt && \
	pip3 install awscli
COPY gpg.sbt /home/jenkins/.sbt/1.0/plugins/gpg.sbt
RUN chown -R jenkins:jenkins /home/jenkins/.sbt
USER jenkins
RUN ls -la /home/jenkins && sbt checkPgpSignatures
