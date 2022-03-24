FROM jenkins/inbound-agent:alpine
USER root
WORKDIR /opt
RUN apk update && apk upgrade musl openssl apk-tools busybox expat libretls && \
              apk add bash curl gnupg && \
              curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
              mv /opt/bin/* /usr/local/bin/ && \
              curl -Ls https://github.com/cli/cli/releases/download/v1.6.2/gh_1.6.2_linux_amd64.tar.gz |  tar --strip-components=1 -xzvf - && \
              mv bin/gh /usr/local/bin && \
              wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/local/bin/jq && \
              chmod +x /usr/local/bin/jq

WORKDIR /opt/plugin-updates
COPY plugin-updates/ .
RUN sbt universal:packageZipTarball && \
              tar -xzf target/universal/tdr-plugin-updates.tgz && \
              cp tdr-plugin-updates/bin/* /usr/bin/ && \
              cp tdr-plugin-updates/lib/* /usr/lib/ && \
              rm -rf /opt/plugin-updates
USER jenkins
COPY entrypoint-for-commit-signing.sh /home/jenkins/entrypoint.sh
RUN git config --global user.email digitalpreservation@nationalarchives.gov.uk
RUN git config --global user.name tna-digital-archiving-jenkins
ENTRYPOINT ["/home/jenkins/entrypoint.sh"]
