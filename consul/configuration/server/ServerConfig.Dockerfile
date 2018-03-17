FROM alpine
ENV REGION="us-east-1a"
ENV ENCRYPTION_TOKEN=""
ENV MANAGER_COUNT=3
WORKDIR /app
COPY server.config.tmpl server.sh ./
ENTRYPOINT ["/bin/sh", "server.sh"]
