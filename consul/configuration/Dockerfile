FROM alpine
ENV REGION="us-east-1a" \
    ENCRYPTION_TOKEN="" \
    MANAGER_COUNT=3
WORKDIR /app
RUN apk update && \
  apk add --no-cache docker && \
  rm -rf /var/cache/apk/*

COPY server.config.tmpl agent.config.tmpl configure.sh ./
ENTRYPOINT ["/bin/sh", "configure.sh"]
