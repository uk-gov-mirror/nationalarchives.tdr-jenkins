FROM jenkins/inbound-agent:alpine
USER root
RUN apk update && apk add curl python3 make gnupg && wget -q https://nodejs.org/dist/v16.9.0/node-v16.9.0-linux-x64.tar.xz && \
                    tar -xf node-v16.9.0-linux-x64.tar.xz --directory /usr/local --strip-components 1 && \
                    apk upgrade openssl apk-tools busybox
USER jenkins
COPY entrypoint-for-commit-signing.sh /home/jenkins/entrypoint.sh
ENTRYPOINT ["/home/jenkins/entrypoint.sh"]
