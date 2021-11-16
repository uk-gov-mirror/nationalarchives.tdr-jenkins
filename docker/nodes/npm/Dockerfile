FROM jenkins/inbound-agent:alpine
USER root
RUN apk update && apk add curl python3 make gnupg npm && \
                    apk upgrade openssl apk-tools busybox
USER jenkins
COPY entrypoint-for-commit-signing.sh /home/jenkins/entrypoint.sh
ENTRYPOINT ["/home/jenkins/entrypoint.sh"]
