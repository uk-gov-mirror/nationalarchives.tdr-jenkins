FROM jenkins/jnlp-slave:alpine
USER root
ENV AWS_DEFAULT_REGION eu-west-2
RUN apk update && \
	apk add py3-pip wget unzip curl && \
        pip3 install awscli && \
	wget https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip && \
	unzip terraform_0.12.28_linux_amd64.zip && \
	mv terraform /usr/bin && \
	terraform --version

USER jenkins
