FROM jenkins/inbound-agent:alpine
USER root
ENV AWS_DEFAULT_REGION eu-west-2
RUN apk update && \
	apk add py3-pip wget unzip curl && \
        pip3 install awscli && \
	apk upgrade openssl apk-tools && \
	wget https://releases.hashicorp.com/terraform/0.13.7/terraform_0.13.7_linux_amd64.zip && \
	unzip -q terraform_0.13.7_linux_amd64.zip && \
	mv terraform /usr/bin && \
	terraform --version && \
        wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O /usr/local/bin/jq && \
        chmod +x /usr/local/bin/jq && \
	wget $(curl https://api.github.com/repos/nationalarchives/tdr-backend-check-performance/releases/latest | jq -r '.assets[0].browser_download_url') && \
	tar -xzf performance.tgz && mv performance/bin/tdr-backend-check-performance /usr/bin/checks && mv performance/lib/* /usr/lib/ 
USER jenkins
RUN checks
