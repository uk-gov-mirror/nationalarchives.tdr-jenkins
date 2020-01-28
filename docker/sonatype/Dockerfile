FROM jenkins/jnlp-slave
USER root 
WORKDIR /home/jenkins
COPY gpg.sbt .sbt/1.0/plugins/gpg.sbt
COPY sonatype.sbt .sbt/1.0/sonatype.sbt
RUN apt-get update && \
        apt-get install -y apt-transport-https python3-pip && \
        echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list && \
        apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
        apt-get update && \
        apt-get install sbt && \
	pip3 install awscli && \
	chown -R jenkins:jenkins .sbt
RUN sbt --version
USER jenkins

