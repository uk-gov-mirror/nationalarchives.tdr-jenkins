FROM jenkins/jnlp-slave 
USER root
ENV AWS_DEFAULT_REGION eu-west-2
RUN apt-get update && \ 
        apt-get install -y apt-transport-https libglib2.0-0 libnss3 xvfb libxi6 curl && \ 
        curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add && \
        echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
        echo "deb https://dl.bintray.com/sbt/debian /" >> /etc/apt/sources.list.d/sbt.list && \ 
        echo "deb http://ppa.launchpad.net/ubuntu-mozilla-security/ppa/ubuntu bionic main" >> /etc/apt/sources.list.d/firefox.list && \ 
        apt-key adv --keyserver hkps://keyserver.ubuntu.com:443 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \    
	    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6DCF7707EBC211F && \
        apt-get -y update && \ 
        apt-get -y install sbt google-chrome-stable firefox && \
        wget -q https://nodejs.org/dist/v12.13.1/node-v12.13.1-linux-x64.tar.xz && \
                            tar -xf node-v12.13.1-linux-x64.tar.xz --directory /usr/local --strip-components 1 
