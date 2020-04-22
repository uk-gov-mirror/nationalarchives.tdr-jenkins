FROM jenkins/jnlp-slave
USER root
COPY *.py /
RUN apt-get update -y \
    && apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl wget jq \
    && curl -O https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tar.xz \
    && tar -xf Python-3.7.3.tar.xz
WORKDIR Python-3.7.3
RUN ./configure --enable-optimizations && make -j 8 && make install
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3 get-pip.py \
    && pip install boto3 \
    && pip install awscli \
    && pip install c7n c7n-mailer \
    && rm /usr/bin/python && ln /usr/local/bin/python3.7 /usr/bin/python
