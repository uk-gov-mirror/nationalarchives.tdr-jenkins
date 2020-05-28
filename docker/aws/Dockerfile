FROM nationalarchives/jenkins-build-python:3.7
USER root
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && pip install boto3 \
    && pip install awscli \
    && rm /usr/bin/python && ln /usr/local/bin/python3.7 /usr/bin/python \
    && pip install c7n c7n-mailer c7n-guardian \
    && pip install ruamel.yaml
COPY *.py /
