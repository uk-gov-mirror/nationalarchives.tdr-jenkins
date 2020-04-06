FROM jenkins/jnlp-slave
USER root
COPY *.py /
RUN apt-get update -y && apt-get install -y python3 jq \
    && curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && pip install boto3 \
    && pip install awscli \
    && pip install c7n c7n-mailer
