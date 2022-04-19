FROM jenkins/inbound-agent:latest-alpine-jdk8
USER root
WORKDIR /opt
RUN apk update && apk add curl postgresql gnupg && \
    apk upgrade musl openssl apk-tools busybox expat libretls zlib nss git && \
    curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
    ln /opt/bin/sbt /usr/local/bin/sbt && ln /opt/bin/sbt-launch.jar /usr/local/bin/sbt-launch.jar
USER jenkins
COPY entrypoint-for-commit-signing.sh /home/jenkins/entrypoint.sh
RUN echo "*:*:*:*:password" > /home/jenkins/.pgpass && chmod 600 /home/jenkins/.pgpass
ENTRYPOINT ["/home/jenkins/entrypoint.sh"]
