FROM jenkins/jnlp-slave:alpine
USER root
RUN apk update && apk add curl && wget -q https://nodejs.org/dist/v12.13.1/node-v12.13.1-linux-x64.tar.xz && \
                    tar -xf node-v12.13.1-linux-x64.tar.xz --directory /usr/local --strip-components 1
