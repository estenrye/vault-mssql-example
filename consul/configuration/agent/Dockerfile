FROM alpine
ENV REGION="us-east-1a"
ENV ENCRYPTION_TOKEN=""
WORKDIR /app
COPY agent.config.tmpl agent.sh ./
ENTRYPOINT ["/bin/sh", "agent.sh"]
