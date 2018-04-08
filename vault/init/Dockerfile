FROM alpine
RUN apk update && \
  apk add --no-cache jq && \
  apk add --no-cache curl && \
  rm -rf /var/cache/apk/*
COPY entrypoint.sh .
ENTRYPOINT [ "/bin/sh", "./entrypoint.sh" ]
