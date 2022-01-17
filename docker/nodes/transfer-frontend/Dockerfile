FROM jenkins/inbound-agent:alpine
USER root
ENV AWS_DEFAULT_REGION eu-west-2
WORKDIR /opt
RUN apk update && apk add curl chromium firefox-esr tar xz npm python3-dev py3-pip && \
    apk upgrade openssl apk-tools busybox && \
    apk upgrade libxml2 && \
    curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
    mv /opt/bin/* /usr/local/bin/ && \
    pip3 install boto3
COPY aws/ssm_get_parameter.py /ssm_get_parameter.py
COPY aws/sessions.py /sessions.py
USER jenkins
RUN git clone https://github.com/nationalarchives/tdr-e2e-tests.git
WORKDIR /opt/tdr-e2e-tests
RUN sbt compile
