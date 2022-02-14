FROM jenkins/inbound-agent:alpine
USER root
ENV AWS_DEFAULT_REGION eu-west-2
RUN apk update && \
	apk add py3-pip wget unzip curl && \
        pip3 install awscli && \
	apk upgrade openssl apk-tools busybox expat && \
	wget https://releases.hashicorp.com/terraform/1.1.3/terraform_1.1.3_linux_amd64.zip && \
	unzip terraform_1.1.3_linux_amd64.zip && \
	mv terraform /usr/bin && \
	terraform --version

USER jenkins
