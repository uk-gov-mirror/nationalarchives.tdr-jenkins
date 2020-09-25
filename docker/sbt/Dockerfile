FROM jenkins/jnlp-slave
USER root 
WORKDIR /home/jenkins
RUN apt-get update && \
        apt-get install -y apt-transport-https && \
        echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list && \
        apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
        apt-get update && \
        apt-get install -y sbt postgresql
USER jenkins
RUN echo "*:*:*:*:password" > /home/jenkins/.pgpass && chmod 600 /home/jenkins/.pgpass
