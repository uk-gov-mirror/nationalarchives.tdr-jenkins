FROM jenkins/jnlp-slave
USER root
COPY update_service.py /
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
                                    && python get-pip.py \
                                    && pip install boto3