FROM alpine
RUN apk update && \
  apk add --no-cache jq && \
  apk add --no-cache curl && \
  apk add --no-cache ca-certificates && \
  update-ca-certificates && \
  rm -rf /var/cache/apk/*
COPY entrypoint.sh .
ENTRYPOINT [ "/bin/sh", "./entrypoint.sh" ]
