FROM jenkins/inbound-agent:alpine
USER root
ENV AWS_DEFAULT_REGION eu-west-2
RUN apk update && \
	apk add py3-pip wget unzip curl && \
        pip3 install awscli && \
	apk upgrade openssl && \
	wget https://releases.hashicorp.com/terraform/0.13.7/terraform_0.13.7_linux_amd64.zip && \
	unzip terraform_0.12.28_linux_amd64.zip && \
	mv terraform /usr/bin && \
	terraform --version

USER jenkins
