FROM alpine
ENV MASTER_TOKEN=""
ENV CONSUL_URI=""

WORKDIR /app
RUN apk update && \
  apk add --no-cache docker && \
  apk add --no-cache jq && \
  apk add --no-cache curl && \
  rm -rf /var/cache/apk/*

COPY acl.json acl.sh ./
ENTRYPOINT [ "/bin/sh", "acl.sh" ]