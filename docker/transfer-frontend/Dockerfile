FROM jenkins/inbound-agent:alpine
USER root
ENV AWS_DEFAULT_REGION eu-west-2
WORKDIR /opt
RUN apk update && apk add curl chromium firefox-esr tar xz && \
    apk upgrade openssl && \
    apk upgrade libxml2 && \
    curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
    mv /opt/bin/* /usr/local/bin/ && \
    wget -q https://nodejs.org/dist/v15.7.0/node-v15.7.0-linux-x64.tar.xz && \
                    tar -xf node-v15.7.0-linux-x64.tar.xz --directory /usr/local --strip-components 1
USER jenkins
