FROM jenkins/jnlp-slave
USER root
RUN apt-get update -y \
    && apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev curl wget jq \
    && curl -O https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tar.xz \
    && tar -xf Python-3.7.3.tar.xz
WORKDIR Python-3.7.3
RUN ./configure --enable-optimizations && make -j 8 && make install
