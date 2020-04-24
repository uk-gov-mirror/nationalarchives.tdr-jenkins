FROM jenkins/jnlp-slave
USER root
ENV AWS_DEFAULT_REGION eu-west-2
RUN apt-get update && \
	apt-get install -y python3 python3-pip wget unzip && \
        pip3 install awscli && \
	wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip && \
	unzip terraform_0.12.24_linux_amd64.zip && \
	mv terraform /usr/bin && \
	terraform --version
