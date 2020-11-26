FROM jenkins/jnlp-slave:alpine
USER root 
WORKDIR /opt
RUN apk update && apk add curl postgresql && \
    rm -rf /opt/java/openjdk && \    
    wget https://cdn.azul.com/zulu/bin/zulu11.43.55-ca-jdk11.0.9.1-linux_musl_x64.tar.gz && \    
    tar -xzf zulu11.43.55-ca-jdk11.0.9.1-linux_musl_x64.tar.gz && \    
    rm zulu11.43.55-ca-jdk11.0.9.1-linux_musl_x64.tar.gz && \
    mv zulu11.43.55-ca-jdk11.0.9.1-linux_musl_x64 /opt/java/openjdk && \
    curl -Ls https://github.com/sbt/sbt/releases/download/v1.4.1/sbt-1.4.1.tgz | tar --strip-components=1 -xzvf - && \
     ln /opt/bin/* /usr/local/bin && ls -la /usr/local/bin
USER jenkins
RUN echo "*:*:*:*:password" > /home/jenkins/.pgpass && chmod 600 /home/jenkins/.pgpass
RUN java --version
