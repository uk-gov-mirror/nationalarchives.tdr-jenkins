FROM jenkins/inbound-agent:alpine
USER root
RUN apk update \
    && apk add curl wget py3-pip gcc python3-dev musl-dev libffi-dev openssl-dev jansson-dev build-base libc-dev file-dev automake autoconf libtool flex bison \
    && pip3 install boto3 \
    && pip3 install awscli \
    && pip3 install c7n c7n-mailer c7n-guardian \
    && pip3 install ruamel.yaml \
    && ln /usr/bin/python3 /usr/bin/python \
    && wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/local/bin/jq \
    && chmod +x /usr/local/bin/jq
COPY *.py /

RUN chown jenkins /*.py
USER jenkins
