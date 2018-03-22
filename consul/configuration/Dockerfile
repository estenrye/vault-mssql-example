FROM alpine
ENV REGION="us-east-2" \
    ENCRYPTION_TOKEN="rp8BG/IebnT1lkKfp9hDyQ==" \
    MASTER_TOKEN="" \
    MANAGER_COUNT=3
WORKDIR /app
RUN apk update && \
  apk add --no-cache docker && \
  apk add --no-cache util-linux && \
  rm -rf /var/cache/apk/*

COPY server.config.tmpl agent.config.tmpl configure.sh ./
ENTRYPOINT ["/bin/sh", "configure.sh"]
