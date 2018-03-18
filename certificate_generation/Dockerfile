FROM alpine
LABEL MAINTAINER='Esten Rye (https://github.com/estenrye)'

RUN apk update && \
  apk add --no-cache openssl && \
  apk add --no-cache docker && \
  apk add --no-cache python && \
  rm -rf /var/cache/apk/*
COPY generateCerts.sh /generateCerts.sh
COPY conf/openssl_root.cnf /ca/root/openssl.cnf
COPY conf/openssl_intermediate.cnf /ca/intermediate/openssl.cnf
COPY conf/openssl_consul.cnf /ca/intermediate/csr/consul.csr.cnf
ENTRYPOINT ["/bin/sh", "/generateCerts.sh"]