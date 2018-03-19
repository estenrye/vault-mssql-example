FROM alpine
LABEL MAINTAINER='Esten Rye (https://github.com/estenrye)'
RUN apk update && \
  apk add --no-cache openssl && \
  apk add --no-cache docker && \
  rm -rf /var/cache/apk/*
# ENV REGION='us-east-1a'
ENV TLD='foo.domain.com'
COPY conf/consul-ca.cnf /etc/consul.d/ssl/CA/myca.conf
COPY generateCerts.sh /generateCerts.sh
# COPY conf/openssl_root.cnf /ca/root/openssl.cnf
# COPY conf/openssl_intermediate.cnf /ca/intermediate/openssl.cnf
# COPY conf/openssl_consul.cnf /ca/intermediate/csr/consul.csr.cnf.tmpl
ENTRYPOINT ["/bin/sh", "/generateCerts.sh"]