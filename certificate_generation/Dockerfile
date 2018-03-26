FROM alpine
LABEL MAINTAINER='Esten Rye (https://github.com/estenrye)'
RUN apk update && \
  apk add --no-cache openssl && \
  apk add --no-cache docker && \
  rm -rf /var/cache/apk/*
ENV REGION='us-east-1a'
ENV TLD='foo.domain.com'

RUN mkdir -p /opt/consul/ssl
COPY conf/consul-ca.cnf /opt/consul/ssl/demo.conf
RUN touch /opt/consul/ssl/certindex && \
    echo 000a > /opt/consul/ssl/serial
WORKDIR /opt/consul/ssl

COPY generateCerts.sh /generateCerts.sh
ENTRYPOINT ["/bin/sh", "/generateCerts.sh"]