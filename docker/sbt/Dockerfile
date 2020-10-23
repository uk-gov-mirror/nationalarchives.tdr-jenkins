FROM jenkins/jnlp-slave:alpine
USER root 
WORKDIR /opt
RUN apk update && apk add curl postgresql && \
    curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
    ln /opt/bin/sbt /usr/local/bin/sbt
USER jenkins
RUN echo "*:*:*:*:password" > /home/jenkins/.pgpass && chmod 600 /home/jenkins/.pgpass
