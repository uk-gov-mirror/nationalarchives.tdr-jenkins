FROM jenkins/jnlp-slave
USER root
COPY *.py /
RUN apt-get update -y && apt-get install -y python3 python3-pip \
    && pip3 install boto3 awscli