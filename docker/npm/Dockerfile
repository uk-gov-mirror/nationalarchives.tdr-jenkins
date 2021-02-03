FROM jenkins/inbound-agent:alpine
USER root
RUN apk update && apk add curl python3 make && wget -q https://nodejs.org/dist/v15.7.0/node-v15.7.0-linux-x64.tar.xz && \
                    tar -xf node-v15.7.0-linux-x64.tar.xz --directory /usr/local --strip-components 1 && \
                    apk upgrade openssl
USER jenkins
