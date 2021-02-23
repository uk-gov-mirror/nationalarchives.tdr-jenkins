FROM jenkins/inbound-agent:alpine
USER root
WORKDIR /opt
RUN apk update && apk add bash curl && \
              curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
              mv /opt/bin/* /usr/local/bin/
WORKDIR /opt/plugin-updates
COPY ./ .
RUN sbt universal:packageZipTarball && \
              tar -xzf target/universal/tdr-plugin-updates.tgz && \
              cp tdr-plugin-updates/bin/* /usr/bin/ && \
              cp tdr-plugin-updates/lib/* /usr/lib/ && \
              rm -rf /opt/plugin-updates
USER jenkins
